class MessagePrinter
  attr_accessor :last_chat_message_at

  def initialize(info_box, chat_box, status_box)
    @info_box = info_box
    @chat_box = chat_box
    @status_box = status_box
    @last_chat_message_at = Time.now
  end

  def print_message(data)
    @data = JSON.parse(data, symbolize_keys: true)

    case @data["box_type"]
    when "info"
      # TODO
    when "status"
      handle_status_message
    when "chat"
      handle_chat_message
    end
  end

  def handle_chat_message
    set_last_chat_message_at

    case @data["type"]
    when "rally_airdrop"
      add_chat_box_message(
        name: "💎💎💎💎💎 #{@data["amount"]} $GEMS FROM RALLY 💎💎💎💎💎",
        name_color: 6,
        time_color: 6
      )
    when "ole_airdrop"
      add_chat_box_message(
        name: "🔮🔮🔮🔮🔮 #{@data["amount"]} $OLE 🔮🔮🔮🔮🔮",
        name_color: 5,
        time_color: 5
      )
      @chat_box.add_message( 5)
    when "host_airdrop"
      add_chat_box_message(
        name: "💎💎💎💎💎 #{@data["amount"]} $GEMS FROM HOST 💎💎💎💎💎",
        name_color: 6,
        time_color: 6
      )
    when "gift"
      add_chat_box_message(
        name: "🎁🎁🎁 GIFT FROM HOST 🎁🎁🎁",
        name_color: 4,
        time_color: 4
      )
    when "user_message"
      add_chat_box_message
    else
      add_chat_box_message
    end
  end

  def handle_status_message
    case @data["type"]
    when "claim_ongoing"
      # TODO
    when "claim_result"
      if @data["amount"].to_i.eql? 0
        add_status_box_message(
          content: "😔😔😔 UNSUCCESSFUL CLAIM, somebody got here before you... 😔😔😔",
          time_color: 6,
          content_color: 6
        )
      else
        add_status_box_message(
          content: "🚀🚀🚀 SUCCESSFUL CLAIM | Claimed #{@data["amount"]} 🚀🚀🚀",
          time_color: 6,
          content_color: 6
        )
      end
    else
      add_status_box_message
    end
  end

  def add_chat_box_message(name: @data['name'], content: @data["content"], name_color: 3, time_color: 2)
    @chat_box.add_colored_text(
      [].tap do |arr|
        arr << { text: "#{@data['time']} | ", color: time_color }
        arr << { text: "#{name}", color: name_color }
        arr << { text: " | #{content}", color: 7 } unless content.empty?
      end
    )
  end

  def add_status_box_message(content: @data["content"], time_color: 3, content_color: 7)
    @status_box.add_colored_text([
      { text: "#{time_to_message} | ", color: time_color },
      { text: "#{content}", color: content_color }
    ])
  end

  def set_last_chat_message_at
    return unless !@data["time"]&.empty?
    @last_chat_message_at = Time.parse(@data["time"])
  end

  def time_to_message
    Time.now.strftime('%I:%M:%S %p')
  end
end