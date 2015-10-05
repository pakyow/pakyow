require 'pakyow-realtime'
require_relative '../../spec_helper'

require_relative 'mixins/pubsub_specs'

shared_examples :websocket_helpers do
  let :response do
    double(:response)
  end

  let :request do
    Rack::Request.new(rack_env)
  end

  let :valid_handshake do
    double(WebSocket::ClientHandshake, valid?: true, accept_response: response)
  end

  let :invalid_handshake do
    double(WebSocket::ClientHandshake, valid?: false, accept_response: response, errors: [:err])
  end

  let :rack_env do
    env = Rack::MockRequest.env_for(url, socket_connection_id: socket_connection_id)
    env['HTTP_UPGRADE'] = header_upgrade
    env['HTTP_SEC_WEBSOCKET_VERSION'] = header_version
    env['HTTP_SEC_WEBSOCKET_KEY'] = header_key
    env['rack.logger'] = Rack::NullLogger.new({})
    env['rack.hijack'] = hijack
    env['rack.hijack_io'] = hijack_io
    env['rack.session'] = { socket_key: socket_key }
    env
  end

  let :rack_env_with_session do
    { 'rack.session' => { socket_key: socket_key } }
  end

  let :url do
    '/'
  end

  let :header_upgrade do
    'websocket'
  end

  let :header_version do
    '1.0'
  end

  let :header_key do
    'foo'
  end

  let :hijack do
    -> {}
  end

  let :hijack_io do
    StringIO.new
  end

  let :socket_key do
    '123'
  end

  let :socket_connection_id do
    '321'
  end

  let :socket_digest do
    socket_key + socket_connection_id
  end
end
