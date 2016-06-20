require 'spec_helper'
require 'pakyow/core/config'
require 'pakyow/core/config/reloader'

describe 'reloader config' do
  before do
    Pakyow::Config.reloader.reset
  end

  it 'is registered' do
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
    end
  end

  describe 'env defaults' do
    context 'for development' do
      before do
        Pakyow::Config.env = :development
      end

      describe 'enabled' do
        it 'is true' do
          expect(Pakyow::Config.reloader.enabled).to eq true
        end
      end
    end

    context 'for production' do
      before do
        Pakyow::Config.env = :production
      end

      describe 'enabled' do
        it 'is false' do
          expect(Pakyow::Config.reloader.enabled).to eq false
        end
      end
    end
  end
end
