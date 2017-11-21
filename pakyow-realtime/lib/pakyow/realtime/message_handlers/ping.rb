# frozen_string_literal: true

# Handles pings to keep the WebSocket alive.
#
Pakyow::Realtime.handler :ping do |_message, _session, response|
  response[:status] = 200
  response[:headers] = {}
  response[:body] = "pong"
  response
end
