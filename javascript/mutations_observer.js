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

  const id = getIdFromNode(node);
  const type = getNodeType(node);
  const currency = getCurrencyFromType(type);
  const airdrop_amount = getAirdropAmount(node);

  node_details.id = id;
  node_details.type = type;
  node_details.airdrop_amount = airdrop_amount;
  node_details.currency = currency;
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

const getCurrencyFromType = (type) => {
  let currency = "";
  if(type == "ole_airdrop") { currency = "OLE" }
  if(type == "rally_airdrop") { currency = "GEMS" }
  if(type == "host_airdrop") { currency = "GEMS" }
  return currency;
}

const getRandomSleepDuration = (ms) => {
  const min = ms * 0.8;
  const max = ms * 2;
  return Math.floor(Math.random() * (max - min) + min); // Use Math.floor to ensure the result is an integer
}

const getAirdropAmount = (node) => {
  const airdropDiv = node.querySelector(".airdrop");
  if (!airdropDiv) { return ""; }
  const innerText = airdropDiv.innerText;
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
  const click_zone = node.querySelector(".airdrop");
  const click_speed = getRandomSleepDuration(speed);
  console.log("speed", speed); // Debug
  console.log("after getRandom speed", click_speed); // Debug

  if(click_zone) {
    setTimeout(() => {
      click_zone.click();
      console.log("Clicked on zone", click_zone); // Debug
    }, click_speed);
  }
}

const sendAirdropChatMessage = (node_details, websocket) => {
  let data            = {};
  data.id             = node_details.id;
  data.box_type       = "chat";
  data.type           = node_details.type;
  data.time           = node_details.time;
  data.currency       = node_details.currency;
  data.airdrop_amount = node_details.airdrop_amount;

  websocket.send(JSON.stringify(data));
}

const sendAirdropStatusAttempt = (node_details, websocket) => {
  let data            = {};
  data.id             = node_details.id;
  data.box_type       = "status";
  data.type           = "claim_attempt";
  data.currency       = node_details.currency;
  data.airdrop_amount = node_details.airdrop_amount;

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
      sendAirdropStatusClaimResult(node_details, amount_claimed);
      claimedSpan.removeEventListener('DOMSubtreeModified', checkClaimAmount);
    }
  }

  const sendAirdropStatusClaimResult = (node_details, amount_claimed) => {
    let data            = {};
    data.id             = node_details.id;
    data.box_type       = "status";
    data.type           = "claim_result";
    data.currency       = node_details.currency;
    data.amount_claimed = parseInt(amount_claimed);

    console.log("sendAirdropStatusClaimResult data", data); // Debug
    websocket.send(JSON.stringify(data));
  };

  checkClaimAmount();
  node.addEventListener('DOMSubtreeModified', checkClaimAmount);

  checkTimeOut = setTimeout(() => {
    sendAirdropStatusClaimResult(node_details, "0");
    node.removeEventListener('DOMSubtreeModified', checkClaimAmount);
  }, 15000);
}

// Initialize observer
const initializeObserver = (chatContainer, websocket, config) => {
  let lastIndex = -1; // Initialize last index variable

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
              sendAirdropChatMessage(node_details, websocket)
              if(canClickAirdrop(node_details, config, websocket)) {
                console.log("Entered canClickAidrop condition") // Debug
                console.log("canClickAidrop config", config) // Debug
                clickAirdrop(node, config.claim_speed);
                sendAirdropStatusAttempt(node_details, websocket);
                checkClaim(node, node_details, websocket);
              }
            } else {
              node_details.box_type = "chat";
              websocket.send(JSON.stringify(node_details));
            }
          }
        });
      }
    });
  };

  const startAndObserve = () => {
    websocket.send(JSON.stringify({
      box_type: "status",
      content: "👀 Mutation observer started successfully. Refresh will occur every 30 minutes."
    }));
    observer.observe(chatContainer, { childList: true, subtree: true });
  };

  const observer = new MutationObserver(observerCallback);
  startAndObserve();

  setInterval(() => {
    websocket.send(JSON.stringify({
      box_type: "status",
      content: "🔄 Refreshing mutation observer..."
    }));
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