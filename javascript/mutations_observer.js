const isValidNode = (node) => {
  return (
    node.nodeType === Node.ELEMENT_NODE &&
    node.hasAttribute('data-index') &&
    node.hasAttribute('data-known-size') &&
    node.hasAttribute('data-item-index')
  );
};

// Claim airdrop from element
const claimAirdrop = (element) => {
  element.click();

  for (let i = 0; i < 10; i++) { setTimeout(() => { element.click(); }, i * 50); }

  const node_details = {
    airdrop: true
  };

  return node_details;
};

// Send chat message
const sendChatMessage = (node) => {
  const message = node.querySelector('.msg-content .content').innerText.trim();
  const name = node.querySelector('.name').innerText.trim();
  const time = node.querySelector('.time').innerText.trim();
  const node_details = {
    airdrop: false,
    name: name,
    message: message,
    time: time
  };

  return node_details;
};

// Start observer
const startObserver = (chatContainer, observerCallback) => {
  const observer = new MutationObserver(observerCallback);

  const options = {
    childList: true,
    subtree: true
  };

  // Start observing the document for configured mutations
  observer.observe(chatContainer, options);

  // Set interval to disconnect and reconnect the observer every 30 seconds
  setInterval(() => {
    console.log("Reconnecting observer...\n");
    observer.disconnect();
    observer.observe(chatContainer, options);
  }, 30000);

  return observer;
};

// Initialize observer
const initializeObserver = (chatContainer, websocket) => {
  let lastIndex = -1; // Initialize last index variable

  const scrollContainer = chatContainer.parentElement.parentElement;

  const observerCallback = (mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        const addedNodes = Array.from(mutation.addedNodes);

        addedNodes.forEach((node) => {
          if (isValidNode(node)) {
            const dataIndex = parseInt(node.getAttribute('data-index'));

            if (dataIndex > lastIndex) {
              const airdropElement = node.querySelector('.airdrop');
              let node_details;

              if (airdropElement) {
                node_details = claimAirdrop(airdropElement);
              } else {
                node_details = sendChatMessage(node);
              }

              // Send node_details to WebSocket server
              websocket.send(JSON.stringify(node_details));

              if (scrollContainer) { scrollContainer.scrollTop = scrollContainer.scrollHeight; }
              lastIndex = dataIndex;
            }
          }
        });
      }
    });
  };

  // Start the observer
  startObserver(chatContainer, observerCallback);
};

// Wrapper to invoke the script from execute_script
((chatContainer) => {
  // Initialize WebSocket connection
  const websocket = new WebSocket('ws://localhost:8080');
  websocket.onopen = () => {
    initializeObserver(chatContainer, websocket);
  };
})(arguments[0]);
