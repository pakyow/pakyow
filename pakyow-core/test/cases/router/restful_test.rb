require 'support/helper'

module Pakyow
  module Test
    class RestfulRouteTest < Minitest::Test
      include ReqResHelpers

      def setup
        Pakyow::App.stage(:test)
        Pakyow.app.context = AppContext.new(mock_request, mock_response)
      end

      def test_actions_are_supported
        set = RouteSet.new
        fn = lambda {}

        set.eval {
          restful :test, 'tests' do
            [:list, :new, :create, :edit, :update, :replace, :show, :delete].each { |a|
              action(a, &fn)
            }
          end
        }

        assert_route_tuple(match: set.match('tests', :get), path: 'tests', name: :list)
        assert_route_tuple(match: set.match('tests/new', :get), path: 'tests/new', name: :new)
        assert_route_tuple(match: set.match('tests', :post), path: 'tests', name: :create)
        assert_route_tuple(match: set.match('tests/1/edit', :get), path: 'tests/:test_id/edit', name: :edit)
        assert_route_tuple(match: set.match('tests/1', :patch), path: 'tests/:test_id', name: :update)
        assert_route_tuple(match: set.match('tests/1', :put), path: 'tests/:test_id', name: :replace)
        assert_route_tuple(match: set.match('tests/1', :get), path: 'tests/:test_id', name: :show)
        assert_route_tuple(match: set.match('tests/1', :delete), path: 'tests/:test_id', name: :delete)
      end

      def test_routes_defined_for_passed_actions_only
        set = RouteSet.new
        fn = lambda {}

        set.eval {
          restful :test, 'tests' do
            action :list, &fn
          end
        }

        assert_route_tuple(match: set.match('tests', :get), path: 'tests', name: :list)
        assert_nil set.match('tests', :post)
      end

      def test_member_routes
        set = RouteSet.new
        fn = lambda {}

        set.eval {
          restful :test, 'tests' do
            member do
              get 'foo', &fn
            end
          end
        }

        assert_route_tuple(match: set.match('tests/1/foo', :get), path: 'tests/:test_id/foo')
      end

      def test_collection_routes
        set = RouteSet.new
        fn = lambda {}

        set.eval {
          restful :test, 'tests' do
            collection do
              get 'foo', &fn
            end
          end
        }

        assert_route_tuple(match: set.match('tests/foo', :get), path: 'tests/foo')
      end

      def test_nested_resources
        set = RouteSet.new
        fn = lambda {}

        set.eval {
          restful :test, 'tests' do
            restful :nest, 'nests' do
              action :list, &fn
            end
          end
        }

        assert_route_tuple(match: set.match('tests/1/nests', :get), path: 'tests/:test_id/nests')
      end

      def test_show_view_path
        skip
      end

      private

      #TODO move to helpers (duped in set_test)
      def assert_route_tuple(opts)
        match = opts[:match]
        
        assert !match.nil?, "Route not found"
        return if match.nil?

        match = match[0]
        assert_equal opts[:regex], match[0],    "mismatched regex"   unless opts[:regex].nil?
        assert_equal opts[:vars],  match[1],    "mismatched vars"    unless opts[:vars].nil?
        assert_equal opts[:name],  match[2],    "mismatched name"    unless opts[:name].nil?
        assert_equal opts[:fns],   match[3][0], "mismatched fn list" unless opts[:fns].nil?
        assert_equal opts[:path],  match[4],    "mismatched path"    unless opts[:path].nil?
      end

    end
  end
end
