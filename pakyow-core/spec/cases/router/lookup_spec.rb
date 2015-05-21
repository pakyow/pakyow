require 'support/helper'

describe Router do
  include ReqResHelpers

  context 'lookup' do
    before do
      Pakyow::App.stage(:test)
      Pakyow.app.context = AppContext.new(mock_request, mock_response)
    end

    it 'gets path for named route' do
      rtr = Router.instance
      rtr.set(:test) {
        get('foo', :foo)
      }

      expect('/foo').to eq RouteLookup.new.path(:foo)
    end

    it 'can populate a path' do
      rtr = Router.instance
      rtr.set(:test) {
        get('foo/:id', :foo1)
        get('foo/bar/:id', :foo2)
      }

      expect('/foo/1').to eq RouteLookup.new.path(:foo1, id: 1)
      expect('/foo/bar/1').to eq RouteLookup.new.path(:foo2, id: 1)
    end

    it 'grouped routes can be looked up by name and group' do
      rtr = Router.instance
      rtr.set(:test) {
        group(:foo) {
          get('bar', :bar)
        }
      }

      expect('/bar').to eq RouteLookup.new.group(:foo).path(:bar)
    end

    it 'namespaced routes can be looked up by name and group' do
      rtr = Router.instance
      rtr.set(:test) {
        namespace('foo', :foo) {
          get('bar', :bar)
        }
      }

      expect('/foo/bar').to eq RouteLookup.new.group(:foo).path(:bar)
      # namespaced route should only be available through group
      expect{ RouteLookup.new.path(:bar) }.to raise_error MissingRoute
    end

    it 'errors when looking up invalid path' do
      expect{ RouteLookup.new.path(:missing) }.to raise_error MissingRoute
    end


    it 'template routes available via expansion name' do
      rtr = Router.instance
      rtr.set(:test) {
        restful :test, 'tests' do
          get 'bar', :bar

          member do
            get 'foo', :foo
          end

          collection do
            get 'meh', :meh
          end
        end
      }

      expect('/tests/bar').to eq RouteLookup.new.group(:test).path(:bar)
      expect('/tests/1/foo').to eq RouteLookup.new.group(:test).path(:foo, { test_id: 1 })
      expect('/tests/meh').to eq RouteLookup.new.group(:test).path(:meh)
    end
  end
end
