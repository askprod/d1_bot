class ConfigFirefox
  attr_accessor :driver

  def initialize(global_config)
    @global_config = global_config
    @config = global_config.config
  end

  def prompt_profile_folder
    folders = @global_config.profiles_folders_list(profile_path).map { |f| f.gsub(/^.*?\./, "")}
    raise "No profiles found. Please check your OS username." if folders.none?
    puts "\n"
    puts "Available Firefox profiles:"
    folders.each.with_index(1) { |f, i| puts "  #{i}. #{folders[i - 1]}" }
    puts "\n"
    print "Enter the number of the profile you want to use: "
    @global_config.parse_toggle_choice(:prompt_browser_config, possible_choices: folders.to_a.map.with_index { |_, i| i.to_i + 1 }.map(&:to_s))
    @config["browser_profile_name"] = folders[@choice.to_i]
  end

  def launch_browser
    options = Selenium::WebDriver::Firefox::Options.new
    options.profile = @config["browser_profile_name"]
    options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3')
    @driver = Selenium::WebDriver.for(:firefox, options: options)
  end

  private

  def profile_path
    translate_path(@global_config.current_os)
  end

  def translate_path(os)
    {
      windows:  "C:/Users/#{@global_config.current_username}/AppData/Roaming/Mozilla/Firefox/Profiles",
      mac_os:   "/Users/#{@global_config.current_username}/Library/Application Support/Firefox/Profiles"
    }[os]
  end
end