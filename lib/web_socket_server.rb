class WebSocketServer
  attr_accessor :client

  def initialize(port, message_printer)
    @clients = []
    @message_printer = message_printer
    @port = port
  end

  def self.run(port, message_printer)
    self.new(port, message_printer).run
  end

  def run
    Thread.new do
      EM.run do
        EM::WebSocket.run(host: '0.0.0.0', port: @port) do |ws|
          ws.onopen do |handshake|
            if @client
              @client.close_connection
            end

            @client = ws
            @clients << ws
            @message_printer.print_message({
              box_type: "status",
              content: "🌐 WebSocket connection successful."
            }.to_json)
          end

          ws.onmessage do |msg|
            @message_printer.print_message(msg)
          end

          ws.onclose do
            @client = nil
            @clients.delete(ws)
            @message_printer.print_message({
              box_type: "status",
              content: "🚫 WebSocket connection closed."
            }.to_json)
          end
        end
      end
    end
  end

  def stop
    @clients.each(&:close_connection)
    EM.stop if EM.reactor_running?
  end
end
