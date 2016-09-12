require 'support/helper'

describe 'Reloading the app' do
  before do
    Pakyow::App.reset
    Pakyow::App.instance_variable_set(:@builder, double(Rack::Builder).as_null_object)
  end

  after do
    Pakyow::App.stage :test
  end

  context 'when reloader is enabled' do
    before do
      Pakyow::App.config.reloader.enabled = true
    end

    it 'uses the reloader middleware' do
      expect(Pakyow::App.builder).to receive(:use).with(Pakyow::Middleware::Reloader)
    end
  end

  context 'when reloader is disabled' do
    before do
      Pakyow::App.config.reloader.enabled = false
    end

    it 'does not use the reloader middleware' do
      expect(Pakyow::App.builder).not_to receive(:use).with(Pakyow::Middleware::Reloader)
    end
  end
end
