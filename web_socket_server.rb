class WebSocketServer
  PORT = 8080

  def initialize
    @clients = []
  end

  def self.call
    self.new.tap do |server|
      server.run
    end
  end

  def run
    Thread.new do
      EM.run {
        EM::WebSocket.run(host: '0.0.0.0', port: PORT) do |ws|
          ws.onopen { |handshake|
            puts "WebSocket connection opened.\n"
            @clients << ws
          }

          ws.onmessage { |msg|
            handle_message(msg)
          }

          ws.onclose {
            puts "WebSocket connection closed.\n"
            @clients.delete(ws)
          }
        end
      }
    end
  end

  def start_chatbox
    @chatbox = ChatBox.new
  end

  def handle_message(msg)
    return unless @chatbox
    data = JSON.parse(msg)
    return handle_airdrop_message(data) if data["airdrop"]
    handle_chat_message(data)
  end

  def log_separator
    '-' * (@chatbox.box_width - 2)
  end

  def handle_airdrop_message(data)
    @chatbox.add_message(log_separator, 2)
    @chatbox.add_message("Airdrop found & claimed.", 1)
  end

  def handle_chat_message(data)
    @chatbox.add_message(log_separator, 2)
    @chatbox.add_colored_text(
      [
        { text: "#{data['name']} ", color: 3 },
        { text: "| #{data['time']} ", color: 7 },
      ]
    )
    @chatbox.add_message("#{data['message']}", 7)
  end
end