require 'core/helpers/running'

module Spec
  class RunningAppMock
    extend Pakyow::Helpers::Running

    Struct.new('Config', :server)
    Struct.new('ServerConfig', :handler, :host, :port)

    MIDDLEWARE = []

    class << self
      attr_accessor :app

      def handler
        'mock'
      end

      def host
        'localhost'
      end

      def port
        4242
      end
    end

    def initialize
      self.class.app = true
    end

    # FIXME: revisit this after refactoring `load_config`
    def self.load_config(*); end

    def self.middleware(*)
      MIDDLEWARE
    end

    def self.config
      Struct::Config.new(Struct::ServerConfig.new(handler, host, port))
    end
  end

  class HandlerMock
    def self.run(*)
    end
  end

  Rack::Handler.register('mock', HandlerMock)
end

describe Pakyow::Helpers::Running do
  let :mock do
    Spec::RunningAppMock
  end

  let :env do
    :mock
  end

  let :envs do
    [env, env]
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
      expect(Pakyow::Helpers::Running::STOP_METHODS).to include('stop!')
    end

    it 'includes `stop`' do
      expect(Pakyow::Helpers::Running::STOP_METHODS).to include('stop')
    end
  end

  describe '::SIGNALS' do
    it 'includes `INT`' do
      expect(Pakyow::Helpers::Running::SIGNALS).to include(:INT)
    end

    it 'includes `TERM`' do
      expect(Pakyow::Helpers::Running::SIGNALS).to include(:TERM)
    end
  end

  describe '::HANDLERS' do
    it 'includes `puma`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include('puma')
    end

    it 'includes `thin`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include('thin')
    end

    it 'includes `mongrel`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include('mongrel')
    end

    it 'includes `webrick`' do
      expect(Pakyow::Helpers::Running::HANDLERS).to include('webrick')
    end
  end

  describe '::prepare' do
    it 'calls `load_config` with envs' do
      expect(mock).to receive(:load_config).with(*envs)
      mock.prepare(*envs)
    end

    it 'appears to be prepared' do
      mock.prepare(*envs)
      expect(mock.prepared?).to be(true)
    end

    it 'calls each middleware block in context of `builder`' do
      block = -> (builder) {}
      mock::MIDDLEWARE << block

      expect(mock).to receive(:instance_exec).with(mock.builder, &block)
      mock.prepare(*envs)
    end

    context 'called when already prepared' do
      before do
        allow(mock).to receive(:prepared?).and_return(true)
      end

      it 'does not call `load_config`' do
        expect(mock).not_to receive(:load_config)
        mock.prepare(*envs)
      end

      it 'does not load middleware' do
        expect(mock).not_to receive(:load_middleware)
        mock.prepare(*envs)
      end

      it 'returns true' do
        expect(mock.prepare(*envs)).to eq(true)
      end
    end
  end

  describe '::stage' do
    context 'passed a single env' do
      it 'prepares with env' do
        expect(mock).to receive(:prepare).with(env)
        mock.stage(env)
      end
    end

    context 'passed multiple envs' do
      let :args do
        [env, env]
      end

      it 'prepares with envs' do
        expect(mock).to receive(:prepare).with(*args)
        mock.stage(*args)
      end
    end

    it 'returns instance' do
      expect(mock.stage).to be_instance_of(mock)
    end
  end

  describe '::run' do
    it 'stages with envs' do
      expect(mock).to receive(:stage).with(*envs)
      mock.run(*envs)
    end

    it 'runs the builder with staged instance' do
      expect(mock.builder).to receive(:run).with(instance_of(mock))
      mock.run(*envs)
    end

    it 'appears to be running' do
      mock.run(*envs)
      expect(mock.running?).to be(true)
    end

    describe 'running the detected handler' do
      let :handler do
        double(Rack::Handler)
      end

      before do
        allow(mock).to receive(:detect_handler).and_return(handler)
      end

      after do
        mock.run(*envs)
      end

      it 'uses the builder' do
        expect(handler).to receive(:run).with(mock.builder, anything)
      end

      it 'sets the Host and Port' do
        expect(handler).to receive(:run).with(anything, {
          Host: mock.host,
          Port: mock.port
        })
      end

      it 'traps each signal' do
        expect(handler).to receive(:run) { |&block|
          block.call
        }

        expect(mock).to receive(:trap).with(Pakyow::Helpers::Running::SIGNALS[0])
        expect(mock).to receive(:trap).with(Pakyow::Helpers::Running::SIGNALS[1])
      end
    end

    context 'called when already running' do
      before do
        allow(mock).to receive(:running?).and_return(true)
      end

      it 'does not run builder' do
        expect(mock.builder).not_to receive(:run)
        mock.run(*envs)
      end

      it 'does not try to detect handler' do
        expect(mock).not_to receive(:detect_handler)
        mock.run(*envs)
      end

      it 'returns true' do
        expect(mock.run(*envs)).to be(true)
      end
    end
  end

  describe '::prepared?' do
    context 'before `prepare` is called' do
      it 'returns false' do
        expect(mock.prepared?).to eq(false)
      end
    end

    context 'after `prepare` is called' do
      before do
        mock.prepare(env)
      end

      it 'returns true' do
        expect(mock.prepared?).to eq(true)
      end
    end
  end

  describe '::running?' do
    context 'before `run` is called' do
      it 'returns false' do
        expect(mock.running?).to eq(false)
      end
    end

    context 'after `run` is called' do
      before do
        mock.run(env)
      end

      it 'returns true' do
        expect(mock.running?).to eq(true)
      end
    end
  end

  describe '::staged?' do
    context 'before `stage` is called' do
      it 'returns false' do
        expect(mock.staged?).to eq(false)
      end
    end

    context 'after `stage` is called' do
      before do
        mock.stage(env)
      end

      it 'returns true' do
        expect(mock.staged?).to eq(true)
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

  describe '::detect_handler' do
    context 'when there\'s a configured handler' do
      it 'prepends the configured handler to the list' do
        mock.detect_handler
        expect(Pakyow::Helpers::Running::HANDLERS).to include(mock.handler)
      end

      it 'only adds the configured handler once' do
        mock.detect_handler
        mock.detect_handler
        expect(Pakyow::Helpers::Running::HANDLERS.count(mock.handler)).to eq(1)
      end
    end

    it 'tries to get each handler' do
      Pakyow::Helpers::Running::HANDLERS.each do |handler|
        expect(Rack::Handler).to receive(:get).with(handler)
      end

      # we want to clear out all registered handlers
      Rack::Handler.instance_variable_set(:@handlers, {})

      begin
        mock.detect_handler
        # rescue the no handler exception
      rescue
      end
    end

    context 'when a handler exists' do
      before do
        Rack::Handler.register('mock', Spec::HandlerMock)
      end

      it 'returns the handler' do
        expect(mock.detect_handler).to be(Spec::HandlerMock)
      end
    end

    context 'when no handler exists' do
      before do
        Rack::Handler.instance_variable_set(:@handlers, {})
      end

      it 'raises an exception' do
        expect { mock.detect_handler }.to raise_exception(RuntimeError)
      end
    end
  end
end
