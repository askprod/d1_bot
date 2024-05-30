class MessagePrinter
  attr_accessor :last_chat_message_at

  def initialize(info_box, chat_box, status_box)
    @info_box = info_box
    @chat_box = chat_box
    @status_box = status_box
    @last_chat_message_at = Time.now
  end

  def print_message(data)
    @data = JSON.parse(data, symbolize_names: true)

    case @data[:box_type]
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

    case @data[:type]
    when "rally_airdrop"
      add_chat_box_message(
        name: "##{@data[:id]} | 💎💎💎💎💎 #{@data[:amount]} $GEMS FROM RALLY 💎💎💎💎💎",
        name_color: 6,
        time_color: 6
      )
    when "ole_airdrop"
      add_chat_box_message(
        name: "##{@data[:id]} | 🔮🔮🔮🔮🔮 #{@data[:amount]} $OLE 🔮🔮🔮🔮🔮",
        name_color: 5,
        time_color: 5
      )
    when "host_airdrop"
      add_chat_box_message(
        name: "##{@data[:id]} | 💎💎💎💎💎 #{@data[:amount]} $GEMS FROM HOST 💎💎💎💎💎",
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
    case @data[:type]
    when "claim_attempt"
      color = @data[:currency].eql?("OLE") ? 5 : 6
      icons = @data[:currency].eql?("OLE") ? "🔮" : "💎"

      add_status_box_message(
        content: "##{@data[:id]} | #{icons} ATTEMPTING TO CLAIM #{@data[:currency]}... #{icons}",
        time_color: color,
        content_color: color
      )
    when "claim_result"
      icons = @data[:currency].eql?("OLE") ? "🔮" : "💎"

      if @data[:amount_claimed].to_i.eql? 0
        add_status_box_message(
          content: "##{@data[:id]} | #{icons} UNSUCCESSFULLY CLAIMED #{@data[:currency]}... #{icons}",
          time_color: 1,
          content_color: 1
        )

        @info_box.update_value(:failed_claims, @info_box.values[:failed_claims] + 1)
      else
        color = @data[:currency].eql?("OLE") ? 5 : 6
        icons = @data[:currency].eql?("OLE") ? "🔮" : "💎"

        add_status_box_message(
          content: "##{@data[:id]} | #{icons} SUCCESSFULLY #{icons} CLAIMED #{@data[:amount_claimed]} $#{@data[:currency]} #{icons}",
          time_color: color,
          content_color: color
        )

        info_box_key = "claimed_#{@data[:currency].downcase}".to_sym
        @info_box.update_value(info_box_key, @info_box.values[info_box_key].to_i + @data[:amount_claimed].to_i)
        @info_box.update_value(:successful_claims, @info_box.values[:successful_claims] + 1)
        @info_box.update_value(:latest_claim, time_to_message(Time.now))
      end
    else
      add_status_box_message
    end
  end

  def add_chat_box_message(name: @data[:name], content: @data[:content], name_color: 3, time_color: 2)
    @chat_box.add_colored_text(
      [].tap do |arr|
        arr << { text: "#{@data[:time]} | ", color: time_color }
        arr << { text: "#{name}", color: name_color }
        arr << { text: " | #{content}", color: 7 } unless (content || "").empty?
      end
    )
  end

  def add_status_box_message(content: @data[:content], time_color: 3, content_color: 7)
    @status_box.add_colored_text([
      { text: "#{time_to_message(Time.now)} | ", color: time_color },
      { text: "#{content}", color: content_color }
    ])
  end

  def set_last_chat_message_at
    return if (@data[:time] || "").empty?
    @last_chat_message_at = Time.parse(@data[:time])
  end

  def time_to_message(time)
    time.strftime('%I:%M:%S %p')
  end
end