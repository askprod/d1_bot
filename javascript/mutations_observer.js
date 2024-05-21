const isValidNode = (node) => {
  return (
    node.nodeType === Node.ELEMENT_NODE &&
    node.hasAttribute('data-index') &&
    node.hasAttribute('data-known-size') &&
    node.hasAttribute('data-item-index')
  );
};

const setNodeDetails = (node) => {
  const airdropDiv = node.querySelector(".airdrop");
  const contentNode = node.querySelector('.msg-content .content');
  const nameNode = node.querySelector('.name');
  const timeNode = node.querySelector('.time');
  const contentText = contentNode ? contentNode.innerText.trim() : "";
  const nameMsg = nameNode ? nameNode.innerText.trim() : "";
  const timeMsg = timeNode ? timeNode.innerText.trim() : "";

  let node_details = {};
  node_details.id = getIdFromNode(node);
  node_details.box_type = "chat";
  node_details.type = getNodeType(node);
  node_details.name = nameMsg;
  node_details.content = contentText;
  node_details.time = timeMsg;
  if(airdropDiv) { node_details.amount = parseAirdropAmount(airdropDiv); }

  console.log("node", node); // debug
  console.log("node_details", node_details);

  return node_details;
};

const parseAirdropAmount = (div) => {
  const innerText = div.innerText;
  const regex = /\d{1,3}(?:,\d{3})*(?:\.\d+)?/;
  const match = innerText.match(regex);
  return match ? parseFloat(match[0].replace(/,/g, '')) : "";
}

const clickAirdrop = (div, node, websocket, speed) => {
  setTimeout(() => {
    div.click();
  }, speed);

  data = {};
  data.id = getIdFromNode(node);
  data.box_type = "status";
  data.type = "claim_attempt"
  data.curreny = getCurrencyFromNode(node);

  websocket.send(JSON.stringify(data));
}

const checkClaim = (div, node, websocket) => {
  setTimeout(() => {
    let data = {};
    let amount_claimed = 0;
    const claimedSpan = div.querySelector('span.flow-root');

    if (claimedSpan) {
      const claimedText = claimedSpan.textContent.trim();
      const match = claimedText.match(/Claimed (\d{1,3}(?:,\d{3})*)\s+\w+/);
      if (match && match[1]) {
        amount_claimed = parseInt(match[1].replace(/,/g, ''), 10);
      }
    }

    data.id = getIdFromNode(node);
    data.box_type = "status";
    data.type = "claim_result";
    data.currency = getCurrencyFromNode(node);
    data.amount_claimed = amount_claimed;

    console.log(data); // debug

    websocket.send(JSON.stringify(data));
  }, 5000);
};

const getIdFromNode = (node) => {
  return node.getAttribute("data-item-index");
}

const getNodeType = (node) => {
  let nodeType = "";
  const airdropDiv = node.querySelector(".airdrop");
  const nameNode = node.querySelector('.name');
  const nameMsg = nameNode ? nameNode.innerText.trim() : "";

  if (airdropDiv) {
    if (nameMsg === "Gems Deliver") {
      nodeType = "rally_airdrop";
    } else if (nameMsg === "OLE Deliver") {
      nodeType = "ole_airdrop";
    } else if (node.querySelector('.airdrop')) {
      nodeType = "host_airdrop";
    }
  } else if (node.querySelector(".css-11b3811")) {
    nodeType = "gift";
  } else {
    nodeType = "user_message";
  }

  return nodeType;
}

const getCurrencyFromNode = (node) => {
  const type = getNodeType(node);
  let currency = "";
  if(type == "ole_airdrop") { currency = "OLE" }
  if(type == "rally_airdrop") { currency = "GEMS" }
  if(type == "host_airdrop") { currency = "GEMS" }
  return currency;
}

// Start observer
const startObserver = (chatContainer, websocket, observerCallback) => {
  const observer = new MutationObserver(observerCallback);

  const options = {
    childList: true,
    subtree: true
  };

  // Start observing the document for configured mutations
  observer.observe(chatContainer, options);

  // Set interval to disconnect and reconnect the observer every 30 seconds
  setInterval(() => {
    websocket.send(JSON.stringify({ type: "status_message", content: "Auto refreshing mutation observer..." }))
    observer.disconnect();
    observer.observe(chatContainer, options);
  }, 120000);

  return observer;
};

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

            if (dataIndex > lastIndex) {
              const airdropDiv = node.querySelector(".airdrop");
              if(airdropDiv) {
                clickAirdrop(airdropDiv, node, websocket, config.claim_speed);
                checkClaim(airdropDiv, node, websocket);
              }
              const node_details = setNodeDetails(node);
              websocket.send(JSON.stringify(node_details));
              lastIndex = dataIndex;
            }
          }
        });
      }
    });
  };

  const startAndObserve = () => {
    sendMessage("👀 Mutation observer started successfully. Refresh will occur every 10 minutes.");
    observer.observe(chatContainer, { childList: true, subtree: true });
  };

  const observer = new MutationObserver(observerCallback);

  startAndObserve();

  setInterval(() => {
    sendMessage("🔄 Refreshing mutation observer...");
    observer.disconnect();
    startAndObserve();
  }, 600000);
};


// Wrapper to invoke the script from execute_script
((chatContainer, config) => {
  const websocket = new WebSocket(`ws://localhost:${config.websocket_port}`);
  websocket.onopen = () => {
    initializeObserver(chatContainer, websocket, config);
  };
})(arguments[0], arguments[1]);