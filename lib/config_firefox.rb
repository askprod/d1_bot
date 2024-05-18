class ConfigFirefox
  attr_accessor :driver

  def initialize(global_config)
    @global_config = global_config
    @config = global_config.config
  end

  def profile_path
    translate_path(@global_config.current_os)
  end

  def prompt_profile_folder
    folders = @global_config.folders_list(profile_path).map { |f| f.gsub(/^.*?\./, "")}
    puts "\n"
    puts "Available Firefox profiles:"
    folders.each.with_index(1) { |f, i| puts "  #{i}. #{folders[i - 1]}" }
    puts "\n"
    print "Enter the number of the profile you want to use: "
    @global_config.parse_toggle_choice(:prompt_profile_folder, possible_choices: folders.to_a.map { |i| i.to_i + 1 }.map(&:to_s))
    @config["firefox_config"]["profile_name"] = folders[@choice.to_i]
  end

  def launch_browser
    puts "\n"
    puts "🚀 Launching Firefox..."
    puts "\n"
    options = Selenium::WebDriver::Firefox::Options.new
    options.profile = @config["firefox_config"]["profile_name"]
    @driver = Selenium::WebDriver.for(:firefox, options: options)
    puts "✅ Firefox launched succesfully."
  end

  private

  def translate_path(os)
    {
      windows:  "C:/Users/#{@config["os_username"]}/AppData/Roaming/Mozilla/Firefox/Profiles",
      mac_os:   "/Users/#{@config["os_username"]}/Library/Application Support/Firefox/Profiles"
    }[os]
  end
end