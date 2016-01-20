require_relative '../spec_helper'
require 'core/config'
require 'core/config/reloader'

describe 'configuration' do
  it 'registers reloader config' do
    expect(Pakyow::Config.reloader).to be_a(Pakyow::Config)
  end

  describe 'options' do
    let :opts do
      Pakyow::Config.reloader
        .instance_variable_get(:@defaults)
        .instance_variable_get(:@opts)
        .keys
    end

    describe 'enabled' do
      it 'is defined' do
        expect(opts).to include(:enabled)
      end

      it 'sets a default enabled value for development' do
        Pakyow::Config.env = :development
        expect(Pakyow::Config.reloader.enabled).to eq(true)
        Pakyow::Config.env = :test
      end

      it 'sets a default enabled value for production' do
        Pakyow::Config.env = :production
        expect(Pakyow::Config.reloader.enabled).to eq(false)
        Pakyow::Config.env = :test
      end
    end
  end
end
