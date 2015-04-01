require 'support/helper'

module Pakyow
  module Test
    class RouteLookupTest < Minitest::Test
      include ReqResHelpers

      def setup
        Pakyow::App.stage(:test)
        Pakyow.app.context = AppContext.new(mock_request, mock_response)
      end

      def test_get_path_for_named_route
        rtr = Router.instance
        rtr.set(:test) {
          get('foo', :foo)
        }

        assert_equal '/foo', RouteLookup.new.path(:foo)
      end

      def test_path_can_be_populated
        rtr = Router.instance
        rtr.set(:test) {
          get('foo/:id', :foo1)
          get('foo/bar/:id', :foo2)
        }

        assert_equal '/foo/1', RouteLookup.new.path(:foo1, id: 1)
        assert_equal '/foo/bar/1', RouteLookup.new.path(:foo2, id: 1)
      end

      def test_grouped_routes_can_be_looked_up_by_name_and_group
        rtr = Router.instance
        rtr.set(:test) {
          group(:foo) {
            get('bar', :bar)
          }
        }

        assert_equal '/bar', RouteLookup.new.group(:foo).path(:bar)
      end

      def test_namespaced_routes_can_be_looked_up_by_name_and_group
        rtr = Router.instance
        rtr.set(:test) {
          namespace('foo', :foo) {
            get('bar', :bar)
          }
        }

        assert_equal '/foo/bar', RouteLookup.new.group(:foo).path(:bar)

        # namespaced route should only be available through group
        assert_raises(MissingRoute) {
          RouteLookup.new.path(:bar)
        }
      end

      def test_errors_when_looking_up_invalid_path
        assert_raises(MissingRoute) {
          RouteLookup.new.path(:missing)
        }
      end


      def test_template_routes_available_via_expansion_name
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

        assert_equal '/tests/bar', RouteLookup.new.group(:test).path(:bar)
        assert_equal '/tests/1/foo', RouteLookup.new.group(:test).path(:foo, { test_id: 1 })
        assert_equal '/tests/meh', RouteLookup.new.group(:test).path(:meh)
      end

    end
  end
end
