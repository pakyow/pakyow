# frozen_string_literal: true

# require "websocket-client-simple"
# require "httparty"
# require "benchmark"
# require "pakyow/core"
# require "pakyow/realtime"

# ENV["SESSION_SECRET"] = "123"
# HOST = "localhost"

# N_CONNS = 1_000
# N_CONNS_PER_PROCESS = 100
# N_MSGS  = 100
# N_APPS  = 10

# PORT_START = 3000

# $rd, $wr = IO.pipe

# processes = []

# begin
#   N_APPS.times do |n_app|
#     processes << Process.fork {
#       Pakyow::App.define do
#         configure do
#           server.port = PORT_START + n_app
#           logger.enabled = false
#           realtime.registry = Pakyow::Realtime::RedisRegistry
#         end

#         routes do
#           CHANNELS = 10.times.map { |n| "channel_#{n}" }

#           get "sub" do
#             socket.subscribe(CHANNELS)
#             send socket_connection_id
#           end

#           post "pub/:msg" do
#             msg = { msg: params[:msg] }
#             chan = CHANNELS.sample

#             N_MSGS.times do
#               begin
#                 socket.push(msg, chan)
#               rescue Exception => e
#                 puts e
#               end
#             end
#           end
#         end
#       end

#       Pakyow::App.run(:production)
#     }
#   end

#   class WebSocketClient
#     def initialize
#       res = HTTParty.get("http://" + File.join(HOST + ":#{port}", "sub"))
#       @key = res.body
#       @cookie = res.headers["set-cookie"]

#       if ws = socket
#         ws.on :message do |_msg|
#           $wr << "."
#         end

#         ws.on :open do
#           # puts 'open'
#         end

#         ws.on :close do |e|
#           # puts 'close'
#         end

#         ws.on :error do |e|
#         end
#       end
#     end

#     def shutdown
#       socket.close
#     end

#     private

#     def socket
#       @socket ||= WebSocket::Client::Simple.connect("ws://" + HOST + ":#{port}/?socket_connection_id=#{@key}", headers: { "COOKIE" => @cookie })
#     end

#     def port
#       PORT_START + (0..(N_APPS - 1)).to_a.sample
#     end
#   end

#   # let our app boot
#   sleep 1

#   # create clients
#   (N_CONNS / N_CONNS_PER_PROCESS).times do
#     processes << Process.fork {
#       clients = []

#       N_CONNS_PER_PROCESS.times do
#         clients << WebSocketClient.new
#       end

#       sleep
#     }
#   end

#   # wait for all clients to connect
#   puts "wait"
#   sleep 15

#   # push messages
#   puts "Pushing #{N_MSGS} messages across 1 channel to #{N_CONNS} connections:"
#   b = Benchmark.measure do
#     HTTParty.post("http://" + File.join(HOST + ":#{PORT_START}", "pub", "hello"))
#   end
#   puts b

#   puts "Waiting for message receipts:"
#   b = Benchmark.measure do
#     total = 0
#     loop do
#       begin
#         total += $rd.read_nonblock(4096).length
#       rescue IO::WaitReadable
#         IO.select([$rd])
#         retry
#       end

#       break if total == N_CONNS * N_MSGS
#     end
#   end
#   puts b
#   puts "DONE"
# ensure
#   processes.each do |process|
#     Process.kill("TERM", process)
#   end
# end
