require 'support/helper'

module Pakyow
  module Test
    class RouterTest < Minitest::Test
      attr_accessor :set_registered
      attr_accessor :fn_calls

      include ReqResHelpers

      def setup
        @fn_calls = []
        Pakyow::App.stage(:test)
        Pakyow.app.context = AppContext.new(mock_request, mock_response)
        Pakyow.app.reload
      end

      def test_router_is_singleton
        assert_same Router.instance, Router.instance
      end

      def test_route_sets_are_registered
        test = self
        Router.instance.set(:test) {
          test.set_registered = true
        }

        assert @set_registered
      end

      def test_routes_can_be_looked_up_by_name
        Router.instance.set(:test) {
          get('foo', :foo) {}
        }

        assert !Router.instance.route(:foo).nil?
        assert_raises(MissingRoute) { Router.instance.route(:bar) }
      end

      def test_route_fns_called_in_order
        binding.pry
        test = self
        Router.instance.set(:test) {
          fn(:one) {
            test.fn_calls << 1
          }

          fn(:two) {
            test.fn_calls << 2
          }

          fn(:three) {
            test.fn_calls << 3
          }

          default [fn(:one), fn(:two), fn(:three)]
        }

        Router.instance.perform(AppContext.new(mock_request))
        assert_equal [1, 2, 3], @fn_calls
      end

      def test_request_can_be_rerouted
        test = self
        Router.instance.set(:test) {
          default {
            app.reroute('foo')
          }

          get('foo') {
            test.fn_calls << :rerouted
          }
        }

        Router.instance.perform(AppContext.new(mock_request))
        assert_equal [:rerouted], @fn_calls
      end

      def test_request_can_be_rerouted_with_method
        test = self
        Router.instance.set(:test) {
          default {
            app.reroute('foo', :put)
          }

          put('foo') {
            test.fn_calls << :rerouted
          }
        }

        Router.instance.perform(AppContext.new(mock_request))
        assert_equal [:rerouted], @fn_calls
      end

      def test_handler_called_from_router
        test = self
        Router.instance.set(:test) {
          default {
            app.handle(500)
          }

          handler(500) {
            test.fn_calls << :handled
          }
        }

        res = Response.new
        Pakyow.app.context = AppContext.new(nil, res)
        Router.instance.perform(AppContext.new(mock_request))

        assert_equal [:handled], @fn_calls
        assert_equal 500, res.status
      end

    end
  end
end
