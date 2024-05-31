window.observerState = {
  shouldClickAirdrops: true,

  updateShouldClickAirdrops: function(shouldClickAirdrops) {
    this.shouldClickAirdrops = shouldClickAirdrops;
  }
};

const isValidNode = (node) => {
  return (
    node.nodeType === Node.ELEMENT_NODE &&
    node.hasAttribute('data-index') &&
    node.hasAttribute('data-known-size') &&
    node.hasAttribute('data-item-index')
  );
};

const setNodeDetails = (node, node_details) => {
  const contentNode = node.querySelector('.msg-content .content');
  const nameNode = node.querySelector('.name');
  const timeNode = node.querySelector('.time');
  const contentText = contentNode ? contentNode.innerText.trim() : "";
  const nameMsg = nameNode ? nameNode.innerText.trim() : "";
  const timeMsg = timeNode ? timeNode.innerText.trim() : "";

  node_details.id = getIdFromNode(node);
  node_details.box_type = "chat";
  node_details.type = getNodeType(node);
  node_details.content = contentText;
  node_details.name = nameMsg;
  node_details.time = timeMsg;
};

// GETTERS

const getIdFromNode = (node) => {
  return node.getAttribute("data-item-index");
}

const getNodeType = (node) => {
  const airdropDiv = node.querySelector(".airdrop");

  if(airdropDiv && airdropDiv.innerText.includes("for Rally")) {
    return "rally_airdrop";
  }

  if(airdropDiv && airdropDiv.innerText.includes("OLE Airdrop")) {
    return "ole_airdrop";
  }

  if(airdropDiv && airdropDiv.innerText.includes("from Host")) {
    return "host_airdrop";
  }

  if(node.querySelector(".css-11b3811")) {
    return "gift";
  }

  return "user_message";
}

const getCurrencyFromType = (node_details) => {
  let currency = "";
  if(node_details.type == "ole_airdrop") { currency = "OLE" }
  if(node_details.type == "rally_airdrop") { currency = "GEMS" }
  if(node_details.type == "host_airdrop") { currency = "GEMS" }
  return currency;
}

const getRandomSleepDuration = (ms) => {
  const min = ms * 0.8;
  const max = ms * 2;
  return parseInt(Math.random() * (max - min) + min);
}

const getAirdropAmount = (node) => {
  const innerText = node.querySelector(".airdrop").innerText;
  const regex = /\d{1,3}(?:,\d{3})*(?:\.\d+)?/;
  const match = innerText.match(regex);
  return match ? parseFloat(match[0].replace(/,/g, '')) : "";
}

// OTHER FUNCTIONS

const nodeIsAirdrop = (node_details) => {
  return (nodeIsGems(node_details) || nodeIsOle(node_details))
}

const nodeIsGems = (node_details) => {
  return [
    "rally_airdrop",
    "host_airdrop"
  ].includes(node_details.type);
}

const nodeIsOle = (node_details) => {
  return (node_details.type == "ole_airdrop");
}

const canClickAirdrop = (node_details, config, websocket) => {
  if(!window.observerState.shouldClickAirdrops) {
    websocket.send(JSON.stringify({
      box_type: "status",
      content: `#${node_details.id} | 🚨 GLOBAL CLAIM DISABLED`
    }));
    return false;
  }

  if(nodeIsOle(node_details) && config.should_claim_ole == false) {
    websocket.send(JSON.stringify({
      box_type: "status",
      content: `#${node_details.id} | 🔮 $OLE CLAIM DISABLED`
    }));
    return false;
  }

  if(nodeIsGems(node_details) && config.should_claim_gems == false) {
    websocket.send(JSON.stringify({
      box_type: "status",
      content: `#${node_details.id} | 💎 $GEMS CLAIM DISABLED`
    }));
    return false;
  }

  return true;
}

const clickAirdrop = (node, speed) => {
  click_zone = node.querySelector(".airdrop");

  if(click_zone) {
    setTimeout(() => {
      click_zone.click();
      console.log("Clicked on zone", zone); // Debug
    }, getRandomSleepDuration(speed));
  }
}

const performAirdropClicks = (node, speed) => {
  const clickTimes = Math.floor(Math.random() * (8 - 3 + 1)) + 3;
  for (let i = 0; i < clickTimes; i++) {
    clickAirdrop(node, speed);
  }
};

const sendAirdropMessage = (node, node_details, websocket) => {
  data = {};
  data.id = node_details.id;
  data.box_type = node_details.box_type;
  data.type = node_details.type;
  data.time = node_details.time;
  data.currency = getCurrencyFromType(node_details);
  data.claim_amount = getAirdropAmount(node);
  websocket.send(JSON.stringify(data));
}

const checkClaim = (node, node_details, websocket) => {
  console.log("Entered checkClaim"); // Debug
  console.log("checkClaim node", node); // Debug
  console.log("checkClaim node_details", node_details); // Debug
  let checkTimeOut;
  let amount_claimed = 0;

  const checkClaimAmount = () => {
    const claimedSpan = node.querySelector('.airdrop span.flow-root');
    if(!claimedSpan) { return; }
    const claimedText = claimedSpan.textContent.trim();
    const match = claimedText.match(/Claimed (\d{1,3}(?:,\d{3})*)\s+\w+/);
    if (match && match[1] !== "0") {
      amount_claimed = parseInt(match[1].replace(/,/g, ''));
      clearTimeout(checkTimeOut);
      sendResult(node_details, amount_claimed);
      claimedSpan.removeEventListener('DOMSubtreeModified', checkClaimAmount);
    }
  }

  const sendResult = (node_details, amount_claimed) => {
    let data = {};
    data.id = node_details.id;
    data.box_type = node_details.box_type;
    data.type = node_details.type;
    data.currency = node_details.currency;
    data.amount_claimed = parseInt(amount_claimed);
    websocket.send(JSON.stringify(data));
  };

  checkClaimAmount();
  node.addEventListener('DOMSubtreeModified', checkClaimAmount);

  checkTimeOut = setTimeout(() => {
    sendResult(node_details, "0");
    node.removeEventListener('DOMSubtreeModified', checkClaimAmount);
  }, 15000);
}

// Initialize observer
const initializeObserver = (chatContainer, websocket, config) => {
  let lastIndex = -1; // Initialize last index variable

  const sendMessage = (message) => {
    websocket.send(JSON.stringify({ box_type: "status", content: message }));
  };

  const scrollContainer = chatContainer.parentElement.parentElement;

  const observerCallback = (mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        const addedNodes = Array.from(mutation.addedNodes);

        addedNodes.forEach((node) => {
          if (isValidNode(node)) {

            scrollContainer.scrollTop = scrollContainer.scrollHeight;
            const dataIndex = parseInt(node.getAttribute('data-index'));

            if(lastIndex > dataIndex) { return;}

            lastIndex = dataIndex;
            let node_details = {}
            setNodeDetails(node, node_details);

            if(nodeIsAirdrop(node_details)) {
              console.log("nodeIsAirdrop node_details", node_details); // Debug
              sendAirdropMessage(node, node_details, websocket)
              if(canClickAirdrop(node_details, config, websocket)) {
                console.log("Entered canClickAidrop condition") // Debug
                performAirdropClicks(node, config.speed);
                checkClaim(node, node_details, websocket);
              }
            } else {
              websocket.send(JSON.stringify(node_details));
            }
          }
        });
      }
    });
  };

  const startAndObserve = () => {
    sendMessage("👀 Mutation observer started successfully. Refresh will occur every 30 minutes.");
    observer.observe(chatContainer, { childList: true, subtree: true });
  };

  const observer = new MutationObserver(observerCallback);
  startAndObserve();

  setInterval(() => {
    sendMessage("🔄 Refreshing mutation observer...");
    observer.disconnect();
    startAndObserve();
  }, 1800000);
};


// Wrapper to invoke the script from execute_script
((chatContainer, config, shouldClickAirdrops) => {
  const websocket = new WebSocket(`ws://localhost:${config.websocket_port}`);
  websocket.onopen = () => {
    window.observerState.updateShouldClickAirdrops(shouldClickAirdrops);
    initializeObserver(chatContainer, websocket, config);
  };
})(arguments[0], arguments[1], arguments[2]);