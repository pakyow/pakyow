require 'spec_helper'
require 'pakyow/core/config'
require 'pakyow/core/config/logger'

RSpec.describe 'logger config' do
  before do
    Pakyow::Config.reloader.reset
  end

  it 'is registered' do
    expect(Pakyow::Config.logger).to be_a(Pakyow::Config)
  end

  describe 'options' do
    let :defaults do
      Pakyow::Config.logger
        .instance_variable_get(:@defaults)
        .instance_variable_get(:@opts)
    end

    let :opts do
      defaults.keys
    end

    describe 'enabled' do
      it 'is defined' do
        expect(opts).to include(:enabled)
      end

      it 'has a default value' do
        expect(defaults[:enabled]).to eq true
      end
    end

    describe 'level' do
      it 'is defined' do
        expect(opts).to include(:level)
      end

      it 'has a default value' do
        expect(defaults[:level]).to eq :debug
      end
    end

    describe 'formatter' do
      it 'is defined' do
        expect(opts).to include(:formatter)
      end

      it 'has a default value' do
        expect(defaults[:formatter]).to eq Pakyow::Logger::DevFormatter
      end
    end
  end

  describe 'env defaults' do
    context 'for production' do
      before do
        Pakyow::Config.env = :production
      end

      describe 'formatter' do
        it 'is Pakyow::Logger::LogfmtFormatter' do
          expect(Pakyow::Config.logger.formatter).to eq Pakyow::Logger::LogfmtFormatter
        end
      end
    end

    context 'for test' do
      before do
        Pakyow::Config.env = :test
      end

      describe 'destinations' do
        it 'does not include $stdout' do
          expect(Pakyow::Config.logger.destinations).not_to include($stdout)
        end
      end
    end
  end
end
