Work in progress

Todo
  - Global
    - ✅ Rename folder configs to config
    - Namespace ruby files and use inheritance
    - ✅ Display config properly in prompt instead instead of just puts
    - Handle when process is exited/browser is closed to properly kill everything
    - ✅ Reload tab/browser if no message has been received in x minutes
    - ✅ Add messages after browser launch:
      - ✅ "60 seconds to of wait until exiting program"
      - ✅ "Connect your wallet and navigate to..."
    - ✅ Add websocket port to config and use it (for multithreading)
    - ✅ Add the config claim_speed in the javascript (only in config for now and doing nothing)
    - ✅ Import and adapt from old version the js to automatically rally if config says so
    - Add the notion of auto voting (not a priority)
    - Make the airdrop message like a regular message (there is a div called .name if it's $OLE)
    - ✅ Not only wait for chat container but also page to be fully loaded before calling the mutations script
    - Write ruby errors to a file
    - ✅ Add possibility to create a config when prompted with list (for now you can only have 1 unless you create the file manually)

Visual improvements of chat
  - ✅ Add box for ruby logs
  - ✅ Add box for current session claimed $GEMS and $OLE and update in realtime
    - Update it with values (ongoing, need to monitor to do so)
  - Add message for CTRL + C to exit next to chat
  - ✅ Scrap and add name of current space above the chat box

Nice to have
  - Send a message in chat at random intervals (with AI ? lol)

Bugs
  - Config prompt is not letting you chose the second config file if you have one