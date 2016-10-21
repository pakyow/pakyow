require 'support/helper'

RSpec.describe Pakyow::Router do
  include ReqResHelpers

  context 'lookup' do
    before do
      Pakyow::App.stage(:test)
      @context = Pakyow::CallContext.new(mock_request.env)
      @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))
    end

    it 'gets path for named route' do
      rtr = Pakyow::Router.instance
      rtr.set(:test) {
        get('foo', :foo)
      }

      expect(Pakyow::RouteLookup.new.path(:foo)).to eq '/foo'
    end

    it 'can populate a path' do
      rtr = Pakyow::Router.instance
      rtr.set(:test) {
        get('foo/:id', :foo1)
        get('foo/bar/:id', :foo2)
      }

      expect(Pakyow::RouteLookup.new.path(:foo1, id: 1)).to eq '/foo/1'
      expect(Pakyow::RouteLookup.new.path(:foo2, id: 1)).to eq '/foo/bar/1'
    end

    it 'grouped routes can be looked up by name and group' do
      rtr = Pakyow::Router.instance
      rtr.set(:test) {
        group(:foo) {
          get('bar', :bar)
        }
      }

      expect(Pakyow::RouteLookup.new.group(:foo).path(:bar)).to eq '/bar'
    end

    it 'namespaced routes can be looked up by name and group' do
      rtr = Pakyow::Router.instance
      rtr.set(:test) {
        namespace('foo', :foo) {
          get('bar', :bar)
        }
      }

      expect(Pakyow::RouteLookup.new.group(:foo).path(:bar)).to eq '/foo/bar'
      # namespaced route should only be available through group
      expect{ Pakyow::RouteLookup.new.path(:bar) }.to raise_error Pakyow::MissingRoute
    end

    it 'errors when looking up invalid path' do
      expect{ Pakyow::RouteLookup.new.path(:missing) }.to raise_error Pakyow::MissingRoute
    end


    it 'template routes available via expansion name' do
      rtr = Pakyow::Router.instance
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

      expect(Pakyow::RouteLookup.new.group(:test).path(:bar)).to eq '/tests/bar'
      expect(Pakyow::RouteLookup.new.group(:test).path(:foo, { test_id: 1 })).to eq '/tests/1/foo'
      expect(Pakyow::RouteLookup.new.group(:test).path(:meh)).to eq '/tests/meh'
    end
  end
end
