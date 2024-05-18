class Driver
  DISTRICT_ONE_MAIN_URL = "https://districtone.io"
  JS_PATH = "./javascript"
  SELENIUM_WAIT_TIMEOUT = 60 # seconds

  def initialize(browser, config)
    @browser = browser
    @driver = @browser.driver
    @config = config
  end

  def launch
    @driver.navigate.to DISTRICT_ONE_MAIN_URL

    puts "\n"
    puts "✅ Navigated to #{DISTRICT_ONE_MAIN_URL}\n"
    puts "\n"
    puts "Go to the 'LIVE' tab when you are ready."
    puts "\n"
    puts "⌛ Waiting for the 'LIVE' tab..."
    puts "\n"

    wait = Selenium::WebDriver::Wait.new(timeout: SELENIUM_WAIT_TIMEOUT)
    wait.until { @driver.current_url.include?('/space/') }
    puts "⌛ Waiting for the chat container element..."

    chat_container = wait.until {
      element = @driver.find_element(css: ".css-vgrroh [data-test-id='virtuoso-item-list']")
      element if element.displayed?
    }

    puts "✅ Chat found."
    puts "\n"
    puts "Starting Websocket server on port #{WebSocketServer::PORT}..."
    puts "\n"

    @websocket_instance = WebSocketServer.call

    js_mutations_code = File.read(File.join(JS_PATH, "mutations_observer.js"))
    @driver.execute_script(js_mutations_code, chat_container)

    puts "✅ Scanning of chat started successfully!\n\n"
    puts "💎💎💎💎💎 Enjoy your free gems and $OLE, courtesy of @sirgmbot 💎💎💎💎💎"
    puts "🚀 Consider dropping some 🐸 $PEPECOINS 🐸 on ETH address if you like the software"
    puts "0xF291d7BAD4F553Ff118bDEE2edEFbE378C3154F7"
    puts "\n"

    @websocket_instance.start_chatbox

    # Keep program running
    loop do
      sleep(1)
    end
  end
end