require 'spec_helper'
require 'pakyow-realtime/websocket'

describe Pakyow::Realtime::Websocket do
  include_examples :websocket_helpers

  let :websocket do
    Pakyow::Realtime::Websocket.new(request, socket_digest)
  end

  before do
    allow(response).to receive(:render)
    allow(WebSocket::ClientHandshake).to receive(:new).and_return(valid_handshake)
  end

  it 'is a child of Connection' do
    expect(Pakyow::Realtime::Websocket.ancestors).to include(Pakyow::Realtime::Connection)
  end

  it 'is a Celluloid actor' do
    expect(Pakyow::Realtime::Websocket.ancestors).to include(Celluloid)
  end

  context 'when terminating the actor' do
    it 'calls shutdown' do
      skip 'not proving to be easy'

      #TODO revisit this
      # expect(websocket).to receive(:shutdown)
      # websocket.terminate
    end
  end

  describe '#initialize' do
    it 'sets @key' do
      expect(websocket.instance_variable_get(:@key)).to eq(socket_digest)
    end

    it 'creates a handshake' do
      headers = {
        'Upgrade' => header_upgrade,
        'Sec-WebSocket-Version' => header_version,
        'Sec-Websocket-Key' => header_key,
      }

      expect(WebSocket::ClientHandshake).to receive(:new).with(:get, "http://example.org#{url}", headers).and_return(valid_handshake)
      websocket
    end

    it 'hijacks the request' do
      skip
    end

    context 'when handshake is valid' do
      let :parser do
        double(WebSocket::Parser, on_message: nil, on_error: nil, on_close: nil, on_ping: nil)
      end

      before do
        allow(WebSocket::ClientHandshake).to receive(:new).and_return(valid_handshake)
      end

      it 'calls accept_response on handshake' do
        expect(valid_handshake).to receive(:accept_response)
        websocket
      end

      it 'renders socket on the response' do
        expect(valid_handshake.accept_response).to receive(:render).with(hijack_io)
        websocket
      end

      it 'creates a websocket parser' do
        expect(WebSocket::Parser).to receive(:new).and_return(parser)
        websocket
      end

      describe 'websocket parser' do
        before do
          allow(WebSocket::Parser).to receive(:new).and_return(parser)
        end

        it 'creates an on_message listener' do
          expect(parser).to receive(:on_message)
          websocket
        end

        it 'creates an on_error listener' do
          expect(parser).to receive(:on_error)
          websocket
        end

        it 'creates an on_close listener' do
          expect(parser).to receive(:on_close)
          websocket
        end

        it 'creates an on_ping listener' do
          expect(parser).to receive(:on_ping)
          websocket
        end
      end
    end

    context 'when handshake is invalid' do
      let :response do
        double(Rack::Response, :reason= => nil, :render => nil)
      end

      before do
        allow(WebSocket::ClientHandshake).to receive(:new).and_return(invalid_handshake)
        allow(Rack::Response).to receive(:new).with(400).and_return(response)
      end

      describe 'response' do
        it 'creates a 400 response' do
          expect(Rack::Response).to receive(:new).with(400)

          begin
            websocket
          rescue Pakyow::Realtime::HandshakeError
          end
        end

        it 'renders socket on the response' do
          expect(response).to receive(:render).with(hijack_io)

          begin
            websocket
          rescue Pakyow::Realtime::HandshakeError
          end
        end

        it 'raises a HandshakeError' do
          expect { websocket }.to raise_error(Pakyow::Realtime::HandshakeError)
        end
      end
    end
  end
end
