require_relative '../spec_helper'
require 'pakyow-realtime/connection'

describe Pakyow::Realtime::Connection do
  let :connection do
    Pakyow::Realtime::Connection.new
  end

  describe '#delegate' do
    it 'returns the delegate singleton' do
      expect(connection.delegate).to eq(Pakyow::Realtime::Delegate.instance)
    end
  end

  describe '#logger' do
    it 'returns the pakyow logger' do
      expect(connection.logger).to eq(Pakyow.logger)
    end
  end
end
