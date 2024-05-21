# selenium-webdriver docs: https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings

# FILES
require "./lib/web_socket_server.rb"
require "./lib/message_printer.rb"
require "./lib/driver.rb"
require "./lib/base_box"
require "./lib/chat_box"
require "./lib/status_box"
require "./lib/info_box"
require "./lib/global_config.rb"
require "./lib/config_firefox.rb"
require "./lib/config_chrome.rb"

# GEMS
require "colorize"
require "selenium-webdriver"
require "os"
require "fileutils"
require "yaml"
require "em-websocket"
require 'json'
require 'curses'
require 'time'

class Launcher
  def initialize()
    GlobalConfig.new
  end
end

Launcher.new