require_relative '../spec_helper'
require 'pakyow-realtime/helpers'
require 'pakyow-realtime/context'

class HelperIncluder
  include Pakyow::Helpers

  def initialize
    @context = AppContext.new(
      Pakyow::Request.new(Rack::MockRequest.env_for('/', method: :get)),
      Pakyow::Response.new
    )
  end

  def session
    @session ||= {}
  end
end

describe 'realtime helpers' do
  let :includer do
    HelperIncluder.new
  end

  describe '#socket' do
    it 'creates a realtime context' do
      expect(Pakyow::Realtime::Context).to receive(:new).with(includer)
      includer.socket
    end

    it 'returns the created context' do
      expect(includer.socket).to be_a(Pakyow::Realtime::Context)
    end
  end

  describe '#socket_key' do
    it 'creates a 32 byte hex string' do
      expect(SecureRandom).to receive(:hex).with(32)
      includer.socket_key
    end

    context 'after creating a hex string' do
      let :hex do
        '123'
      end

      before do
        allow(SecureRandom).to receive(:hex).and_return(hex)
      end

      it 'returns the created hex string' do
        expect(includer.socket_key).to eq(hex)
      end

      it 'sets session[:socket_key] with the created hex string' do
        includer.socket_key
        expect(includer.session[:socket_key]).to eq(hex)
      end
    end

    describe 'subsequent calls' do
      it 'does not replace current session[:socket_key] value' do
        includer.session[:socket_key] = :foo
        includer.socket_key
        expect(includer.socket_key).to eq(:foo)
      end
    end
  end

  describe '#socket_connection_id' do
    it 'creates a 32 byte hex string' do
      expect(SecureRandom).to receive(:hex).with(32)
      includer.socket_connection_id
    end

    context 'after creating a hex string' do
      let :hex do
        '123'
      end

      before do
        allow(SecureRandom).to receive(:hex).and_return(hex)
      end

      it 'returns the created hex string' do
        expect(includer.socket_connection_id).to eq(hex)
      end
    end

    describe 'subsequent calls' do
      it 'does not replace current value' do
        includer.instance_variable_set(:@socket_connection_id, :foo)
        includer.socket_connection_id
        expect(includer.socket_connection_id).to eq(:foo)
      end
    end
  end

  describe '#socket_digest' do
    it 'creates a digest with key + conn_id' do
      conn_id = '321'
      expect(Digest::SHA1).to receive(:hexdigest).with("--#{includer.socket_key}--#{conn_id}--")
      includer.socket_digest(conn_id)
    end
  end
end
