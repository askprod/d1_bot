class WebSocketServer
  attr_accessor :clients, :thread

  def initialize(port, message_printer)
    @clients = []
    @message_printer = message_printer
    @port = port
  end

  def self.run(port, message_printer)
    self.new(port, message_printer).tap { |w| w.run }
  end

  def run
    @thread = Thread.new do
      EM.run do
        EM::WebSocket.run(host: '0.0.0.0', port: @port) do |ws|
          ws.onopen { handle_on_open(ws) }
          ws.onmessage { |msg| handle_on_message(ws, msg) }
          ws.onclose { handle_on_close(ws) }
          ws.onerror { |error| handle_on_error(ws, error) }
        end
      end
    end
  end

  def stop
    @clients.each(&:close_connection)
    @clients.clear
    EM.stop_event_loop if EM.reactor_running?
  end

  private

  def handle_on_open(ws)
    @clients << ws
    @message_printer.print_message({ box_type: "status", content: "🌐 WebSocket connection successful."}.to_json)
  end

  def handle_on_message(_, msg)
    @message_printer.print_message(msg)
  end

  def handle_on_close(ws)
    @message_printer.print_message({ box_type: "status", content: "🚫 WebSocket connection closed." }.to_json)
    @clients.delete(ws)
  end

  def handle_on_error(ws, error)
    @message_printer.print_message({ box_type: "status", content: "🚫 WebSocket error." }.to_json)
    @message_printer.print_message({ box_type: "status", content: "🚫 Error: #{error}" }.to_json)
    ws.close
  end
end
