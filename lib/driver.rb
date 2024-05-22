class Driver
  DISTRICT_ONE_MAIN_URL = "https://districtone.io"
  JS_PATH = "./javascript"
  SELENIUM_WAIT_TIMEOUT = 60 # seconds

  def initialize(browser, config)
    @browser = browser
    @config = config

    ### Flags
    @browser_initialized = false
    @curses_boxes_initialized = false
    @websocket_initialized = false
    @shutdown_requested = false
    @shutdown_requested = false

    ## Mutexes
    # https://stackoverflow.com/questions/26435095/ruby-using-a-mutex-to-keep-threads-from-stopping-prematurely
    @shutdown_mutex = Mutex.new
    @print_status_mutex = Mutex.new
  end

  def launch
    setup_signal_traps
    initialize_selenium_wait_timer
    initialize_curses_boxes
    initialize_browser
    navigate_and_wait_for_tab
    initialize_web_socket
    initialize_live_tab
    initialize_threads
  ensure
    stop_execution
  end

  private

  def setup_signal_traps
    trap("INT") { request_shutdown }
    trap("TERM") { request_shutdown }
  end

  def initialize_browser
    print_status_message("⌛ Launching browser...")
    sleep(3)
    @browser.launch_browser
    @driver = @browser.driver
    @browser_initialized = true
    print_status_message("💥 Firefox launched succesfully.")
  end

  def navigate_and_wait_for_tab
    @driver.get DISTRICT_ONE_MAIN_URL
    print_status_message("💥 Navigated to #{DISTRICT_ONE_MAIN_URL}")
    sleep(1)
    print_status_message("⏱️ Program will exit in 60 seconds if no action is done.")
    sleep(1)
    print_status_message("🔓 Connect your wallet to login to district.io.")
    sleep(1)
    print_status_message("🎙️ Once ready, go to the 'LIVE' tab.")
    sleep(1)
    print_status_message("⌛ Waiting for the 'LIVE' tab...")
  end

  def initialize_selenium_wait_timer
    @wait = Selenium::WebDriver::Wait.new(timeout: SELENIUM_WAIT_TIMEOUT)
  end

  def initialize_web_socket
    print_status_message("⌛ Starting Websocket server on port #{@config["websocket_port"]}...")
    sleep(5)
    @websocket = WebSocketServer.run(@config["websocket_port"], @message_printer)
    @websocket_initialized = true
  end

  def initialize_curses_boxes
    Curses.clear
    Curses.curs_set(0)

    @info_box = InfoBox.new
    @status_box = StatusBox.new(@info_box)
    @chat_box = ChatBox.new(@status_box)
    @curses_boxes_initialized = true

    @message_printer = MessagePrinter.new(@info_box, @chat_box, @status_box)
  end

  def initialize_live_tab
    wait_for_space_url

    print_status_message("⌛ Waiting for the chat container element...")

    wait_for_chat_container

    print_status_message("💥 Chat found.")
    sleep(1)
    print_status_message("⌛ Starting chat scan...")
    sleep(3) # Make sure page loads completely.

    wait_for_space_name

    initialize_mutation_observer

    print_status_message("💥 Scanning of chat started successfully!")
  end

  def initialize_mutation_observer
    js_mutations_code = File.read(File.join(JS_PATH, "mutations_observer.js"))
    @driver.execute_script(js_mutations_code, @chat_container, @config)
  end

  def initialize_threads
    threads = []

    if can_auto_rally?
      threads << Thread.new do
        loop { sleep(10); check_auto_rally; sleep(590) }
      end
    end

    threads << Thread.new do
      loop do
        sleep(1800)
        refresh_browser if should_refresh_browser?
      end
    end

    threads << Thread.new do
      sleep(60)
      update_uptime
    end

    threads << Thread.new do
      loop do
        sleep(1)
        stop_execution if shutdown_requested?
      end
    end

    threads.each(&:join)
  end

  def wait_for_space_url
    @wait.until { @driver.current_url.include?('/space/') }
  end

  def wait_for_chat_container
    @chat_container = @wait.until {
      element = @driver.find_element(css: ".css-vgrroh [data-test-id='virtuoso-item-list']")
      element if element.displayed?
    }
  end

  def wait_for_space_name
    @wait.until {
      element = @driver.find_element(css: ".css-1q1av42 h2")
      @info_box.update_value(:space_name, element.text) if element.displayed?
      true
    }
  end

  def check_auto_rally
    begin
      print_status_message("🤔 Checking if you can rally...")
      rally_button = @driver.find_element(:css, ".css-pladf5 .rally-button")
      rally_button.click
      print_status_message("🥳 You have been rallied!")
    rescue Selenium::WebDriver::Error::NoSuchElementError
      print_status_message("😢 No rally found. Will try again in 10 minutes.")
    end
  end

  def update_uptime
    @info_box.update_value(:total_uptime, @info_box.values[:total_uptime] + 1)
  end

  def request_shutdown
    @shutdown_mutex.synchronize { @shutdown_requested = true }
    Thread.new { stop_execution }
  end

  def stop_execution
    EM.stop           if EM.reactor_running?
    close_boxes       if curses_boxes_initialized?
    puts "🚫 Gracefully stopping..."
    puts "\n"
    @websocket.stop   if websocket_initialized?
    @driver.quit      if browser_initialized?
    exit
  end

  def close_boxes
    @info_box.close
    @status_box.close
    @chat_box.close
    Curses.close_screen
  end

  def refresh_browser
    print_status_message("💀 No chat message received in 30 minutes!")
    print_status_message("⌛ Refreshing page and scripts...")
    @chat_box.empty_content
    @driver.navigate.refresh
    @websocket.stop if @websocket
    initialize_web_socket
    initialize_live_tab
  end

  def should_refresh_browser?
    @message_printer.last_chat_message_at < (Time.now - (20 * 60)) # 20 minutes
  end

  def print_status_message(content)
    @print_status_mutex.synchronize do
      @message_printer.print_message({ box_type: "status", content: content }.to_json)
    end
  end

  def can_auto_rally?
    @config["auto_rally"]
  end

  def shutdown_requested?
    @shutdown_mutex.synchronize { @shutdown_requested }
  end

  def browser_initialized?
    @browser_initialized
  end

  def curses_boxes_initialized?
    @curses_boxes_initialized
  end

  def websocket_initialized?
    @websocket_initialized
  end
end