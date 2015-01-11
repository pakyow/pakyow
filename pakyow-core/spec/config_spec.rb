require 'support/helper'

describe Pakyow::Config do
  before do
    Pakyow::Config.register :test do |config|
      config.opt :foo, :bar
      config.opt :proc, lambda { File.join(foo.to_s, 'proc') }
      config.opt :proc_arg, lambda { |arg| File.join(foo.to_s, arg, 'proc') }
    end
  end

  after do
    Pakyow::Config.deregister :test
  end

  it 'registers config' do
    expect(Pakyow::Config.instance_variable_get(:@config)).to include(:test)
  end

  it 'creates getter for registered config' do
    expect(Pakyow::Config.test).to be_instance_of(Pakyow::Config)
  end

  it 'deregisters config' do
    Pakyow::Config.deregister :test
    expect(Pakyow::Config.instance_variable_get(:@config)).to_not include(:test)
  end

  it 'sets default value for config option' do
    expect(Pakyow::Config.test.foo).to eq(:bar)
  end

  it 'evals proc values' do
    expect(Pakyow::Config.test.proc).to eq('bar/proc')
  end

  it 'passes args to proc values' do
    expect(Pakyow::Config.test.proc_arg('foo')).to eq('bar/foo/proc')
  end

  context 'with env-specific values' do
    before do
      Pakyow::Config.test.env :test do |opts|
        opts.foo = :foo
      end
    end

    after do
      Pakyow::Config.test.clear_env :test
    end

    it 'gives precedence to env value' do
      expect(Pakyow::Config.test.foo).to eq(:foo)
    end

    it 'clears the env value' do
      Pakyow::Config.test.clear_env :test
      expect(Pakyow::Config.test.foo).to eq(:bar)
    end
  end

  context 'with app-specific values' do
    before do
      Pakyow::Config.app_config do
        test.foo = :app
      end
    end

    after do
      Pakyow::Config.reset
    end

    it 'gives precedence to app value' do
      expect(Pakyow::Config.test.foo).to eq(:app)
    end

    it 'resets the app value' do
      Pakyow::Config.reset
      expect(Pakyow::Config.test.foo).to eq(:bar)
    end
  end
  
  describe 'config option added after registration' do
    before do
      Pakyow::Config.test.opt(:external, :value)
    end
    
    it 'sets the config option' do
      expect(Pakyow::Config.test.external).to eq(:value)
    end
    
    it 'protects the default value from reset' do
      Pakyow::Config.reset
      expect(Pakyow::Config.test.external).to eq(:value)
    end
    
    it 'allows the default value to be overridden' do
      Pakyow::Config.test.external = :value2
      expect(Pakyow::Config.test.external).to eq(:value2)
    end
  end
end
