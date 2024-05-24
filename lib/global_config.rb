class GlobalConfig
  CONFIG_PATH = "./config"
  attr_accessor :config, :current_os, :current_username

  def initialize()
    set_os
    set_os_username
    set_template_config_file
    prompt_config
  end

  def set_os
    puts "\n"
    puts "Checking your OS..."
    puts "\n"
    sleep(1)
    raise "Program can only run on MacOS or Windows" unless OS.windows? or OS.mac?
    @current_os = OS.windows? ? :windows : :mac_os
    puts "Your are running on #{translate_os(@current_os)}"
  end

  def set_os_username
    puts "\n"
    puts "Checking your username..."
    puts "\n"
    sleep(1)
    @current_username = ENV["USERNAME"] if @current_os.eql? :windows
    @current_username = ENV["USER"] if @current_os.eql? :mac_os
    puts "Your username is #{@current_username}"
  end

  def set_template_config_file
    @template_config_filename = "template.yml"
    @template_config_file = File.join(CONFIG_PATH, @template_config_filename)
    raise "Config template file not found." unless File.exist? @template_config_file
  end

  def set_config
    paths = Dir.glob(File.join(CONFIG_PATH, "*.yml")).reject { |file| File.basename(file) == @template_config_filename }
    @config_filenames = paths.map { |f| f.gsub("#{CONFIG_PATH}/", "").gsub(".yml", "") }
  end

  def prompt_config
    set_config

    unless has_any_config?
      puts "\n"
      puts "No configuration found."
      create_config
      return
    end

    puts "\n"
    puts "Available profiles:"
    config_choices = @config_filenames.unshift("Create a new config...")
    config_choices.each.with_index(1) { |f, i| puts "  #{i}. #{config_choices[i - 1]}" }
    puts "\n"
    print "Enter the number of the config you want to use: "
    parse_toggle_choice(:prompt_config, possible_choices: config_choices.to_a.map.with_index { |_, i| i.to_i + 1 }.map(&:to_s))
    return create_config if @choice.to_i.eql? 1
    @current_config_name = config_choices[choice_to_int - 1]
    @current_config_file_path = "#{CONFIG_PATH}/#{@current_config_name}.yml"
    file = File.read(@current_config_file_path)
    @config = YAML.safe_load(file)
    prompt_change_or_keep_config
  end

  def prompt_change_or_keep_config
    puts "\n"
    puts "Current configuration '#{@current_config_name}':"
    puts "\n"
    log_config
    puts "\n"
    print "Would you like to change it? (y/n) "
    parse_toggle_choice(:prompt_change_or_keep_config)

    if choice_to_boolean.eql? true
      prompt_auto_rally
      prompt_claim_speed
      prompt_websocket_port
      prompt_browser_choice
      set_browser_config
      prompt_browser_config
      write_config_to_file
      launch_driver
    else
      set_browser_config
      launch_driver
    end
  end

  def has_any_config?
    @config_filenames.any?
  end

  def create_config
    puts "\n"
    puts "Creating a new config..."
    puts "\n"
    print "Enter the name of your new config: (ex. 'default_chrome') "
    puts "\n"
    filename = gets.chomp
    new_file = File.join(CONFIG_PATH, "#{filename}.yml")
    template_content = File.read(@template_config_file)
    File.write(new_file, template_content)
    puts "Config created with success."
    prompt_config
  end

  def prompt_auto_rally
    puts "\n"
    print "Do you want to rally automatically? (y/n) "
    parse_toggle_choice(:prompt_auto_rally)
    @config["auto_rally"] = choice_to_boolean
  end

  def prompt_claim_speed
    puts "\n"
    puts "Available claim speeds: "
    puts "  1. #{'Slow'.colorize(:green)} (500ms)"
    puts "  2. #{'Correct'.colorize(:yellow)} (250ms)"
    puts "  3. #{'Blazing Fast'.colorize(:red)} (< 100ms)"
    puts "\n"
    print "At what speed would you like to claim airdops when they appear? (the slower the less obvious): "
    parse_toggle_choice(:prompt_claim_speed, possible_choices: ["1", "2", "3"])
    @config["claim_speed"] = choice_to_speed
  end

  def prompt_websocket_port
    puts "\n"
    puts "Choose your port for the local Websocket instance."
    puts "If you are running multiple instances of this code, make sure they are different everytime."
    print "Enter your port (default: 8080): "
    port = gets.chomp
    return prompt_websocket_port unless valid_websocket_port?(port)
    @config["websocket_port"] = port
  end

  def prompt_browser_choice
    puts "\n"
    print "Do you want to use Firefox? (y/n) "
    parse_toggle_choice(:prompt_browser_choice)
    return @config["browser_choice"] = "firefox" if choice_to_boolean.eql? true
    puts "\n"
    puts "Do you want to use Chrome? (y/n) "
    parse_toggle_choice(:prompt_browser_choice)
    return @config["browser_choice"] = "chrome" if choice_to_boolean.eql? true
    raise "No browser chosen."
  end

  def set_browser_config
    if @config["browser_choice"].eql? "chrome"
      @current_browser = ConfigChrome.new(self)
    else
      @current_browser = ConfigFirefox.new(self)
    end
  end

  def prompt_browser_config
    @current_browser.prompt_profile_folder
  end

  def write_config_to_file
    File.open(@current_config_file_path, "w") { |file| file.write(@config.to_yaml) }
  end

  def launch_driver
    Driver.new(@current_browser, @config).launch
  end

  def profiles_folders_list(path)
    Dir.glob("#{path}/*").map { |entry| (entry.gsub("#{path}/", "")) if File.directory?(entry) }
  end

  def log_config
    @config.each do |k, v|
      puts "#{k.gsub("_", " ").capitalize}: #{v}"
    end
  end

  # Check if user input contains only the choices
  def parse_toggle_choice(caller_method, possible_choices: ["y", "n"])
    @choice = gets.chomp

    unless possible_choices.include? @choice
      @choice = nil
      send(caller_method)
    end
  end

  def choice_to_boolean
    {
      y: true,
      n: false,
    }[@choice.to_sym]
  end

  def choice_to_speed
    puts @choice
    {
      1 => "80",
      2 => "250",
      3 => "500"
    }[@choice.to_i]
  end

  def choice_to_int
    return @choice.to_i if @choice.to_i.is_a? Integer
  end

  def valid_websocket_port?(port)
    port_regex = /\A([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])\z/
    !!(port.to_s =~ port_regex)
  end

  def translate_os(os)
    {
      "windows": "Windows",
      "mac_os":  "Mac OS"
    }[os]
  end
end