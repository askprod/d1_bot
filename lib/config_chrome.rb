class ConfigChrome
  attr_accessor :driver

  def initialize(global_config)
    @global_config = global_config
    @config = global_config.config
  end

  def profile_path
    translate_path(@global_config.current_os)
  end

  def prompt_profile_folder
    puts profile_path
    puts @global_config.folders_list(profile_path)
    folders = @global_config.folders_list(profile_path).map { |f| f.gsub(/^.*?\./, "")}
    puts "\n"
    puts "Available Chrome profiles:"
    folders.each.with_index(1) { |f, i| puts "  #{i}. #{folders[i - 1]}" }
    puts "\n"
    print "Enter the number of the profile you want to use: "
    @global_config.parse_toggle_choice(:prompt_profile_folder, possible_choices: folders.to_a.map { |i| i.to_i + 1 }.map(&:to_s))
    @config["chrome_config"]["profile_name"] = folders[@choice.to_i]
  end

  def launch_browser
    puts "\n"
    puts "⌛ Launching Chrome..."
    puts "\n"
    options = Selenium::WebDriver::Chrome::Options.new
    profile_dir = "#{profile_path}/#{@config["chrome_config"]["profile_name"]}"
    options.add_argument("--user-data-dir=#{profile_dir}")
    @driver = Selenium::WebDriver.for(:chrome, options: options)
    puts "💥 Chrome launched successfully."
  end

  private

  def translate_path(os)
    {
      windows:  "C:/Users/#{@config["os_username"]}/AppData/Local/Google/Chrome/User Data",
      mac_os:   "/Users/#{@config["os_username"]}/Library/Application Support/Google/Chrome"
    }[os]
  end
end