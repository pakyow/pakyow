require_relative '../../spec_helper'

require 'pakyow-support'
require 'core/helpers/configuring'

module Spec
  class ConfiguringAppMock
    def self.before(*); end
    def load_routes; end

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

  describe '::define' do
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

  describe '::routes' do
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

      it 'returns the app' do
        expect(mock.routes(name, &block)).to eq(mock)
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

  describe '#routes' do
    let :mock_instance do
      mock.new
    end

    let :set_name do
      :mock
    end

    let :block do
      -> (*) {}
    end

    it 'calls `::routes` with set name and block' do
      expect(mock).to receive(:routes).with(set_name, &block)
      mock_instance.routes(set_name, &block)
    end

    it 'loads the routes' do
      expect(mock_instance).to receive(:load_routes)
      mock_instance.routes(set_name, &block)
    end
  end

  describe '::resource' do
    let :set_name do
      :mock
    end

    let :path do
      '/mock'
    end

    let :block do
      -> {}
    end

    context 'called with a block' do
      context 'and a set name' do
        context 'and a path' do
          before do
            @original_resource_actions = Pakyow::Helpers::Configuring::RESOURCE_ACTIONS
            Pakyow::Helpers::Configuring.send(:remove_const, 'RESOURCE_ACTIONS')
            Pakyow::Helpers::Configuring::RESOURCE_ACTIONS = {
              mock: -> (app, set_name, path, block) {
                @resource_action_app = app
                @resource_action_set_name = set_name
                @resource_action_path = path
                @resource_action_block = block
              }
            }
          end

          after do
            Pakyow::Helpers::Configuring.send(:remove_const, 'RESOURCE_ACTIONS')
            Pakyow::Helpers::Configuring::RESOURCE_ACTIONS = @original_resource_actions
          end

          it 'calls each resource action block with app, set name, path, and block' do
            mock.resource(set_name, path, &block)

            expect(@resource_action_app).to eq(mock)
            expect(@resource_action_set_name).to eq(set_name)
            expect(@resource_action_path).to eq(path)
            expect(@resource_action_block).to eq(block)
          end
        end

        context 'and without a path' do
          it 'raises an ArgumentError' do
            expect { mock.resource(set_name, &block) }.to raise_error(ArgumentError)
          end
        end
      end

      context 'and without a set name' do
        it 'raises an ArgumentError' do
          expect { mock.resource(&block) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'called without a block' do
      context 'and with a set name' do
        it 'raises an ArgumentError' do
          expect { mock.resource(set_name) }.to raise_error(ArgumentError)
        end
      end

      context 'and without a set name' do
        it 'raises an ArgumentError' do
          expect { mock.resource }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#resource' do
    let :mock_instance do
      mock.new
    end

    let :set_name do
      :mock
    end

    let :path do
      '/mock'
    end

    let :block do
      -> (*) {}
    end

    it 'calls `::resource` with set name, path, and block' do
      expect(mock).to receive(:resource).with(set_name, path, &block)
      mock_instance.resource(set_name, path, &block)
    end
  end

  describe '::RESOURCE_ACTIONS' do
    let :set_name do
      :mock
    end

    let :path do
      '/mock'
    end

    let :block do
      -> {}
    end

    let :actions do
      Pakyow::Helpers::Configuring::RESOURCE_ACTIONS
    end

    it 'contains a proc for `core`' do
      expect(actions.keys).to include(:core)
    end

    describe '`core` proc' do
      it 'accepts four arguments' do
        expect(actions[:core].arity).to eq(4)
      end

      it 'registers a route set with set name' do
        expect(mock).to receive(:routes).with(set_name)
        actions[:core].call(mock, set_name, path, block)
      end
    end
  end

  describe '::middleware' do
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

  describe '::configure' do
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
      it 'assumes global to be the env name' do
        mock.configure(&block)
        expect(config[:global]).to eq(block)
      end
    end

    context 'called without a block' do
      it 'raises an argument error' do
        expect { mock.configure(env) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '::extended' do
    after do
      mock.extend(Pakyow::Helpers::Configuring)
    end

    it 'registers a before reload hook' do
      expect(mock).to receive(:before).with(:reload)
    end

    it 'includes instance methods' do
      expect(mock).to receive(:include).with(Pakyow::Helpers::Configuring::InstanceMethods)
    end
  end
end
