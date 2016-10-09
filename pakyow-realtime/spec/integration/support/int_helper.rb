require "pakyow/realtime"
require "spec_helper"

require "pakyow/support/silenceable"

PORT = 2001
HOST = "localhost"

class Pakyow::CallContext
  include Pakyow::Support::Silenceable
end

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
        silence_warnings do
          socket.push(params[:message], params[:channel])
        end
      end

      post '/:socket' do
        silence_warnings do
          socket.push_to_key(params[:message], params[:channel], params[:socket])
        end
      end
    end

    get '/ws' do
      send socket_connection_id
    end
  end
end

require "httparty"

$server = nil
def start_server(host: HOST, port: PORT)
  return if $server && check_for_server
  original_stdout = $stdout.clone
  $stdout.reopen(File.new('/dev/null', 'w'))
  $server = Thread.new {
    Pakyow::App.run(:production)
  }
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

    Pakyow::Support::Silenceable.silence_warnings do
      @client = WebSocketClient.new(
        host: host,
        port: port,
        path: path
      )
    end

    @client
  end

  include Pakyow::Support::Silenceable
  attr_reader :socket, :socket_digest, :messages

  def initialize(host: HOST, port: PORT, path: "ws")
    silence_warnings do
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
  end

  def shutdown
    silence_warnings do
      @socket.close
    end
  end
end

require "event_emitter"
# Class from websocket-client-simple with silenced warnings.
# https://rubygems.org/gems/websocket-client-simple/
module WebSocket
  module Client
    module Simple

      def self.connect(url, options={})
        client = ::WebSocket::Client::Simple::Client.new
        yield client if block_given?
        client.connect url, options
        return client
      end

      class Client
        include Pakyow::Support::Silenceable
        include EventEmitter
        attr_reader :url, :handshake

        def connect(url, options={})
          return if @socket
          @url = url
          uri = URI.parse url
          @socket = TCPSocket.new(uri.host,
                                  uri.port || (uri.scheme == 'wss' ? 443 : 80))
          if ['https', 'wss'].include? uri.scheme
            ctx = OpenSSL::SSL::SSLContext.new
            ctx.ssl_version = options[:ssl_version] || 'SSLv23'
            ctx.verify_mode = options[:verify_mode] || OpenSSL::SSL::VERIFY_NONE #use VERIFY_PEER for verification
            cert_store = OpenSSL::X509::Store.new
            cert_store.set_default_paths
            ctx.cert_store = cert_store
            @socket = ::OpenSSL::SSL::SSLSocket.new(@socket, ctx)
            @socket.connect
          end
          @handshake = ::WebSocket::Handshake::Client.new :url => url, :headers => options[:headers]
          @handshaked = false
          @pipe_broken = false
          @frame = ::WebSocket::Frame::Incoming::Client.new
          @closed = false
          once :__close do |err|
            close
            emit :close, err
          end

          @thread = Thread.new do
            silence_warnings do
              while !@closed do
                begin
                  unless recv_data = @socket.getc
                    sleep 1
                    next
                  end
                  unless @handshaked
                    @handshake << recv_data
                    if @handshake.finished?
                      @handshaked = true
                      emit :open
                    end
                  else
                    @frame << recv_data
                    while msg = @frame.next
                      emit :message, msg
                    end
                  end
                rescue => e
                  emit :error, e
                end
              end
            end
          end

          silence_warnings do
            @socket.write @handshake.to_s
          end
        end

        def send(data, opt={:type => :text})
          return if !@handshaked or @closed

          silence_warnings do
            type = opt[:type]
            frame = ::WebSocket::Frame::Outgoing::Client.new(:data => data, :type => type, :version => @handshake.version)
            begin
              @socket.write frame.to_s
            rescue Errno::EPIPE => e
              @pipe_broken = true
              emit :__close, e
            end
          end
        end

        def close
          return if @closed

          silence_warnings do
            if !@pipe_broken
              send nil, :type => :close
            end
            @closed = true
            @socket.close if @socket
            @socket = nil
            emit :__close
            Thread.kill @thread if @thread
          end
        end

        def open?
          @handshake.finished? and !@closed
        end

      end

    end
  end
end
