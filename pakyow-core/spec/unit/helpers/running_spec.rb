require 'spec_helper'
require 'pakyow/core/helpers/running'

module Spec
  class RunningAppMock
    extend Pakyow::Helpers::Running

    Struct.new('Config', :server, :app)
    Struct.new('ServerConfig', :handler, :host, :port)
    Struct.new('AppConfig', :src_dir)

    MIDDLEWARE = []

    class << self
      attr_accessor :app

      def handler
        HandlerMock
      end

      def host
        'localhost'
      end

      def port
        4242
      end

      def src_dir
        'app/lib'
      end

      def load_config
      end
    end

    def initialize
      self.class.app = true
    end

    # FIXME: revisit this after refactoring `load_config`
    def self.load_env_config(*); end

    def self.middleware(*)
      MIDDLEWARE
    end

    def self.config
      Struct::Config.new(
        Struct::ServerConfig.new(handler, host, port),
        Struct::AppConfig.new(src_dir)
      )
    end
  end

  class HandlerMock
    def self.run(*)
    end
  end
end

RSpec.describe Pakyow::Helpers::Running do
  let :mock do
    Spec::RunningAppMock
  end

  let :env do
    :mock
  end

  before do
    allow(Pakyow).to receive(:app) { mock.app }
  end

  after do
    mock.instance_variables.each do |ivar|
      mock.remove_instance_variable(ivar)
    end
  end

  describe '::STOP_METHODS' do
    it 'includes `stop!`' do
      expect(Pakyow::Helpers::Running::STOP_METHODS).to include(:stop!)
    end

    it 'includes `stop`' do
      expect(Pakyow::Helpers::Running::STOP_METHODS).to include(:stop)
    end
  end

  describe '::SIGNALS' do
    it 'includes `INT`' do
      expect(Pakyow::Helpers::Running::STOP_SIGNALS).to include(:INT)
    end

    it 'includes `TERM`' do
      expect(Pakyow::Helpers::Running::STOP_SIGNALS).to include(:TERM)
    end
  end

  describe '::HANDLERS' do
    it 'includes `puma`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include(:puma)
    end

    it 'includes `thin`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include(:thin)
    end

    it 'includes `webrick`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include(:webrick)
    end
  end

  describe '::prepare' do
    it 'calls `load_env_config` with env' do
      expect(mock).to receive(:load_env_config).with(env)
      mock.prepare(env)
    end

    it 'calls each middleware block in context of `builder`' do
      block = -> (builder) {}
      mock::MIDDLEWARE << block

      expect(mock).to receive(:instance_exec).with(mock.builder, &block)
      mock.prepare(env)
    end

    it 'adds src_dir to load path' do
      mock.prepare(env)
      expect($LOAD_PATH).to include(mock.src_dir)
    end
  end

  describe '::stage' do
    context 'passed a single env' do
      it 'prepares with env' do
        expect(mock).to receive(:prepare).with(env)
        mock.stage(env)
      end
    end

    context 'passed multiple env' do
      let :args do
        [env]
      end

      it 'prepares with env' do
        expect(mock).to receive(:prepare).with(*args)
        mock.stage(*args)
      end
    end

    it 'returns instance' do
      expect(mock.stage(env)).to be_instance_of(mock)
    end
  end

  describe '::run' do
    it 'stages with env' do
      expect(mock).to receive(:stage).with(env)
      mock.run(env)
    end

    it 'runs the builder with staged instance' do
      expect(mock.builder).to receive(:run).with(instance_of(mock))
      mock.run(env)
    end

    describe 'running the detected handler' do
      let :handler do
        double(Rack::Handler)
      end

      after do
        mock.run(env)
      end

      it 'uses the builder' do
        expect(mock.handler).to receive(:run).with(mock.builder, anything)
      end

      it 'sets the Host and Port' do
        expect(mock.handler).to receive(:run).with(anything, {
          Host: mock.host,
          Port: mock.port
        })
      end

      it 'traps each signal' do
        expect(mock.handler).to receive(:run) { |&block|
          block.call
        }

        expect(mock).to receive(:trap).with(Pakyow::Helpers::Running::STOP_SIGNALS[0])
        expect(mock).to receive(:trap).with(Pakyow::Helpers::Running::STOP_SIGNALS[1])
      end
    end
  end

  describe '::builder' do
    it 'returns a rack builder' do
      expect(mock.builder).to be_instance_of(Rack::Builder)
    end

    context 'called again' do
      before do
        @builder = mock.builder
      end

      it 'returns the same builder' do
        expect(mock.builder).to be(@builder)
      end
    end
  end
end
