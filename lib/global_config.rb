class GlobalConfig
  CONFIGS_PATH = "./configs"
  attr_accessor :config, :current_os

  def initialize()
    set_os
    set_template_config_file
    prompt_configs
  end

  def set_os
    puts "Checking your OS..."
    puts "\n"
    raise "Program can only run on MacOS or Windows" unless OS.windows? or OS.mac?
    @current_os = OS.windows? ? :windows : :mac_os
    puts "Your are running on #{translate_os(@current_os)}"
  end

  def set_template_config_file
    @template_config_filename = "template.yml"
    @template_config_file = File.join(CONFIGS_PATH, @template_config_filename)
    raise "Config template file not found." unless File.exist? @template_config_file
  end

  def set_configs
    paths = Dir.glob(File.join(CONFIGS_PATH, "*.yml")).reject { |file| File.basename(file) == @template_config_filename }
    @config_filenames = paths.map { |f| f.gsub("#{CONFIGS_PATH}/", "").gsub(".yml", "") }
  end

  def prompt_configs
    set_configs

    unless has_any_configs?
      puts "No configuration found."
      create_config
      return
    end

    puts "\n"
    puts "Available profiles:"
    @config_filenames.each.with_index(1) { |f, i| puts "  #{i}. #{@config_filenames[i - 1]}" }
    puts "\n"
    print "Enter the number of the config you want to use: "
    # TODO Add option to create_profile ?
    parse_toggle_choice(:prompt_configs, possible_choices: @config_filenames.to_a.map { |i| i.to_i + 1 }.map(&:to_s))
    @current_config_file_path = "#{CONFIGS_PATH}/#{@config_filenames[choice_to_int - 1]}.yml"
    file = File.read(@current_config_file_path)
    @config = YAML.safe_load(file)
    prompt_change_or_keep_config
  end

  def prompt_change_or_keep_config
    puts "\n"
    puts "Here is your config:"
    puts "\n"
    log_config(@config)
    puts "\n"
    print "Would you like to change it? (y/n) "
    parse_toggle_choice(:prompt_change_or_keep_config)

    if choice_to_boolean.eql? true
      prompt_username
      prompt_auto_rally
      prompt_claim_speed
      prompt_browser_choice
      set_browser_config
      prompt_browser_config
      write_config_to_file
      launch_browser
      launch_driver
    else
      set_browser_config
      launch_browser
      launch_driver
    end
  end

  def has_any_configs?
    @config_filenames.any?
  end

  def create_config
    puts "Creating a new config..."
    puts "\n"
    print "Enter the name of your new config: (ex. 'default_chrome') "
    puts "\n"
    filename = gets.chomp
    new_file = File.join(CONFIGS_PATH, "#{filename}.yml")
    template_content = File.read(@template_config_file)
    File.write(new_file, template_content)
    puts "Config created with success."
    prompt_configs
  end

  def prompt_username
    puts "\n"
    print "Enter your username on this PC (ex. 'admin'): "
    @config["os_username"] = gets.chomp.strip
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
    puts "  1. #{'Slow'.colorize(:green)} (200ms)"
    puts "  2. #{'Correct'.colorize(:yellow)} (100ms)"
    puts "  3. #{'Blazing Fast'.colorize(:red)} (< 50ms)"
    puts "\n"
    print "At what speed would you like to claim airdops when they appear? (the slower the less obvious): "
    parse_toggle_choice(:prompt_claim_speed, possible_choices: ["1", "2", "3"])
    @config["claim_speed"] = choice_to_int
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

  def launch_browser
    @current_browser.launch_browser
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

  # TODO rename, only used for profiles folder
  def folders_list(path)
    Dir.glob("#{path}/*").map { |entry| (entry.gsub("#{path}/", "")) if File.directory?(entry) }
  end

  def log_config(config)
    # TODO Print as something nice
    puts config
  end

  # Check if user input contains only the choices
  def parse_toggle_choice(caller_method, possible_choices: ["y", "n"])
    @choice = gets.chomp

    unless possible_choices.include? @choice
      @choice = nil
      send(caller_method).call
    end
  end

  def choice_to_boolean
    {
      y: true,
      n: false,
    }[@choice.to_sym]
  end

  def choice_to_int
    return @choice.to_i if @choice.to_i.is_a? Integer
  end

  def translate_os(os)
    {
      "windows": "Windows",
      "mac_os":  "Mac OS"
    }[os]
  end
end