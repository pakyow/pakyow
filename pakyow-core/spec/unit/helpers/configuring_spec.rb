require 'pakyow-support'
require 'core/helpers/configuring'

module Spec
  class ConfiguringAppMock
    extend Pakyow::Helpers::Configuring
  end
end

describe Pakyow::Helpers::Configuring do
  let :mock do
    Spec::ConfiguringAppMock
  end

  after do
    mock.instance_variables.each do |ivar|
      mock.remove_instance_variable(ivar)
    end
  end

  describe '#define' do
    context 'called with a block' do
      before do
        @result = mock.define do
          @foo = :bar
        end
      end

      it 'sets the path to the file defining the app' do
        expect(mock.path).to eq(__FILE__)
      end

      it 'evals the block' do
        expect(mock.instance_variable_get(:@foo)).to eq(:bar)
      end

      it 'returns the app' do
        expect(@result).to eq(mock)
      end
    end

    context 'called without a block' do
      it 'raises an argument error' do
        expect { mock.define }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#routes' do
    let :block do
      -> {}
    end

    context 'called with a name and a block' do
      let :name do
        :foo
      end

      before do
        mock.routes(name, &block)
      end

      it 'registers the routes' do
        expect(mock.routes[name]).to eq(block)
      end
    end

    context 'called without a name' do
      before do
        mock.routes(&block)
      end

      it 'assumes the name' do
        expect(mock.routes.values.last).to eq(block)
      end
    end

    context 'called without a block' do
      before do
        mock.routes(&block)
      end

      let :routes do
        mock.routes
      end

      it 'returns the registered routes' do
        expect(routes).to be_instance_of(Hash)
        expect(routes.keys.first).to eq(:main)
        expect(routes.values.first).to eq(block)
      end
    end
  end

  describe '#middleware' do
    let :block do
      -> {}
    end

    before do
      mock.middleware(&block)
    end

    context 'called with a block' do
      it 'registers the middleware' do
        expect(mock.middleware).to include(block)
      end
    end

    context 'called without a block' do
      let :middleware do
        mock.middleware
      end

      it 'returns the registered middleware' do
        expect(middleware).to be_instance_of(Array)
        expect(middleware.first).to eq(block)
      end
    end
  end

  describe '#configure' do
    let :config do
      mock.instance_variable_get(:@config)
    end

    let :env do
      :dev
    end

    let :block do
      -> {}
    end

    context 'called with an env name and a block' do
      before do
        mock.configure(env, &block)
      end

      it 'registers the configuration' do
        expect(config[env]).to eq(block)
      end
    end

    context 'called without an env name' do
      it 'raises an argument error' do
        expect { mock.configure(&block) }.to raise_error(ArgumentError)
      end
    end

    context 'called without a block' do
      it 'raises an argument error' do
        expect { mock.configure(env) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#load_config' do
    # TODO: test this once that part of Pakyow::App is refactored
  end
end
