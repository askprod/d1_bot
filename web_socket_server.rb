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
            if @client
              puts "Closing previous connection."
              @client.close_connection
            end

            @client = ws
          }

          ws.onclose {
            puts "WebSocket connection closed.\n"
            @client = nil
          }
        end
      }
    end
  end

  def start_handling_messages(chatbox)
    return unless @client
    @client.onmessage { |msg|
      MessagePrinter.new(chatbox, JSON.parse(msg)).print_message
    }
  end
end