class BaseBox
  attr_reader :box_width, :box_height, :top_offset

  def initialize(height_ratio, top_offset = 0, border_color_pair = 2)
    @height_ratio = height_ratio
    @top_offset = top_offset
    @border_color_pair = border_color_pair
    add_box
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
    @win.close
  end

  protected

  def add_box
    Curses.start_color

    initialize_color_pairs

    # Calculate dimensions
    @max_height, @max_width = Curses.lines, Curses.cols
    @box_height = (@max_height * @height_ratio).to_i
    @box_width = (@max_width).to_i
    top = @top_offset
    left = (@max_width - @box_width) / 2

    # Create the window
    @win = Curses::Window.new(@box_height, @box_width, top, left)
    draw_box(@win, @border_color_pair)
    @win.refresh

    @messages = []
  end

  def initialize_color_pairs
    @color_pairs_initialized ||= begin
      Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLACK)
      Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
      Curses.init_pair(3, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
      Curses.init_pair(4, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
      Curses.init_pair(5, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
      Curses.init_pair(6, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
      Curses.init_pair(7, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
      true
    end
  end

  def draw_box(window, color_pair)
    window.attron(Curses.color_pair(color_pair)) do
      window.box('|', '-')
    end
  end

  def empty_content
    @messages = []
    display_content
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
              @win.addstr(segment[:text].encode('utf-8')[0, @box_width - 2 - @win.curx]) # Ensure the message fits within the width
            end
          end
        else
          @win.attron(Curses.color_pair(msg[:color])) do
            @win.addstr(msg[:text].encode('utf-8')[0, @box_width - 2]) # Ensure the message fits within the width
          end
        end
        current_line += 1
      end
    end

    draw_box(@win, @border_color_pair) # Redraw the box border
    @win.refresh
  end
end
