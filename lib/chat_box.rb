require 'curses'

class ChatBox
  attr_reader :box_width

  def initialize
    add_chat_box
  end

  def add_chat_box
    Curses.init_screen
    Curses.start_color

    # Initialize color pairs
    Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
    Curses.init_pair(5, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
    Curses.init_pair(6, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.init_pair(7, Curses::COLOR_WHITE, Curses::COLOR_BLACK)

    Curses.clear # Clear the terminal after initializing the screen
    Curses.curs_set(0) # Hide the cursor

    # Calculate dimensions
    @max_height, @max_width = Curses.lines, Curses.cols
    @box_height = (@max_height * 2 / 3).to_i
    @box_width = (@max_width * 2 / 3).to_i
    top = (@max_height - @box_height) / 2
    left = (@max_width - @box_width) / 2

    # Create a window
    @win = Curses::Window.new(@box_height, @box_width, top, left)
    draw_box
    @win.refresh

    @messages = []
  end

  def add_message(message, color_pair = 7)
    @messages << { text: message, color: color_pair }
    display_content
  end

  def add_colored_text(segments)
    @messages << segments
    display_content
  end

  def close
    Curses.close_screen
  end

  private

  def draw_box
    @win.attron(Curses.color_pair(2)) do # Green color for the border
      @win.box('|', '-')
    end
  end

  def display_content
    content_start = 0
    max_content_height = @box_height - 2

    if @messages.size > max_content_height
      content_start = @messages.size - max_content_height
    end

    # Clear the content area only
    (@box_height - 2).times do |i|
      @win.setpos(i + 1, 1)
      @win.clrtoeol
    end

    current_line = 1
    @messages[content_start..-1].each do |msg|
      if current_line < @box_height - 1
        @win.setpos(current_line, 1)
        if msg.is_a?(Array)
          msg.each do |segment|
            @win.attron(Curses.color_pair(segment[:color])) do
              @win.addstr(segment[:text][0, @box_width - 2 - @win.curx]) # Ensure the message fits within the width
            end
          end
        else
          @win.attron(Curses.color_pair(msg[:color])) do
            @win.addstr(msg[:text][0, @box_width - 2]) # Ensure the message fits within the width
          end
        end
        current_line += 1
      end
    end

    draw_box # Redraw the box border
    @win.refresh
  end
end