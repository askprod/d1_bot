class InfoBox < BaseBox
  attr_accessor :values

  def initialize(config)
    super(1.0 / 4, 0, 6) # InfoBox will occupy 1/4 of the screen height and start at the top with a yellow border
    @config = config
    set_static_message
    set_messages_value
    display_static_message
    display_dynamic_zones
  end

  def update_value(key, value)
    @values[key] = value
    display_dynamic_zones
  end

  private

  def set_static_message
    @static_message = [
      "💎💎💎💎💎 Enjoy your free $GEMS and $OLE, courtesy of @sirgmbot 💎💎💎💎💎",
      "ETH address: 0xF291d7BAD4F553Ff118bDEE2edEFbE378C3154F7"
    ]
  end

  def set_messages_value
    @values = {
      # Col 1
      space_name: "N/A",
      claimed_ole: 0,
      claimed_gems: 0,
      # Col 2
      latest_claim: "N/A",
      successful_claims: 0,
      failed_claims: 0,
      # Col 3
      app_started_at: Time.now.strftime("%d/%m %I:%M %p"),
      total_uptime: 0,
      config: "Autorally: #{@config["auto_rally"]} | WSPort: #{@config["websocket_port"]}"
    }
  end

  def display_static_message
    @static_message.each_with_index do |line, index|
      @win.setpos(1 + index, (@box_width - line.length) / 2)
      @win.addstr(line)
    end
    @win.refresh
  end

  def display_dynamic_zones
    # Define the zones
    left_zone = [
      "-" * (@box_width / 3 - 3),
      "Current space: #{@values[:space_name]}",
      "🔮 Claimed $OLE: #{@values[:claimed_ole]}",
      "💎 Claimed $GEMS: #{@values[:claimed_gems]}"
    ]

    middle_zone = [
      "-" * (@box_width / 3 - 3),
      "Latest Claim: #{@values[:latest_claim]}",
      "Successful claims: #{@values[:successful_claims]}",
      "Failed claims: #{@values[:failed_claims]}"
    ]

    right_zone = [
      "-" * (@box_width / 3 - 3),
      "App started at: #{@values[:app_started_at]}",
      "Total uptime: #{@values[:total_uptime]} minutes",
      @values[:config]
    ]

    # Set zone width
    zone_width = @box_width / 3

    # Clear previous content
    clear_content_area

    # Display static message first
    display_static_message

    # Display zones
    zones = [left_zone, middle_zone, right_zone]
    zones.each_with_index do |zone, zone_index|
      zone.each_with_index do |line, line_index|
        centered_text = line.center(zone_width - 2)
        @win.setpos(4 + line_index, zone_index * zone_width + 1)
        @win.addstr(centered_text)
      end
    end

    @win.refresh
  end

  def clear_content_area
    (@box_height - 2).times do |i|
      @win.setpos(i + 1, 1)
      @win.clrtoeol
    end
    draw_box(@win, @border_color_pair)
  end
end