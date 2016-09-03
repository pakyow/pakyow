require "pakyow/realtime"
require "spec_helper"

PORT = 2001
HOST = "localhost"

Pakyow::App.define do
  configure do
    server.port = PORT
    server.host = HOST
    logger.level = :error
    logger.formatter = Pakyow::Logger::DevFormatter
    session.secret = "sekret"
  end

  routes do
    default do
      res.body = ["<body></body>"]
    end

    get '/sub/:channel' do
      socket.subscribe(params[:channel])
      send socket_connection_id
    end
    
    namespace '/push' do
      post '/' do
        socket.push(params[:message], params[:channel])
      end
      
      post '/:socket' do
        socket.push_to_key(params[:message], params[:channel], params[:socket])
      end
    end
    
    get '/ws' do
      send socket_connection_id
    end
  end
end

require "websocket-client-simple"
require "httparty"

def start_server(host: HOST, port: PORT)
  return if $server && check_for_server
  original_stdout = $stdout.clone
  $stdout.reopen(File.new('/dev/null', 'w'))
  $server = Thread.new { Pakyow::App.run(:production) }
  check_for_server
  $stdout.reopen(original_stdout)
end

def restart_server(host: HOST, port: PORT)
  $server.terminate if $server
  start_server(host: host, port: port)
end

def check_for_server(host: HOST, port: PORT)
  attempts = 0
  until attempts == 10
    begin
      HTTParty.get("http://#{host}:#{port}")
      return true
    rescue Errno::ECONNREFUSED
      attempts += 1
      sleep 0.1
    end
  end
  
  fail "could not connect"
end

class WebSocketClient
  def self.create(host: HOST, port: PORT, path: "ws")
    check_for_server

    return WebSocketClient.new(
      host: host,
      port: port,
      path: path
    )
  end

  attr_reader :socket, :socket_digest, :messages

  def initialize(host: HOST, port: PORT, path: "ws")
    res = HTTParty.get(File.join("http://#{host}:#{port}", path))
    
    socket_id = res.body
    cookie = res.headers["set-cookie"]
    
    @messages = []
    
    @socket = WebSocket::Client::Simple.connect(
      "ws://#{host}:#{port}/?socket_connection_id=#{socket_id}",
      headers: { 'COOKIE' => cookie }
    )
    
    received = -> (message) {
      @messages << message.data.to_s
    }

    @socket.on :message do |message|
      received.call(message)
    end

    @socket.on :open do; end
    @socket.on :close do; end
    @socket.on :error do; end
  end

  def shutdown
    @socket.close
  end
end
