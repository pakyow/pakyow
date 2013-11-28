require 'support/helper'

module Pakyow
  module Test
    class RouteSetTest < Minitest::Test

      def setup
        Pakyow::App.stage(:test)
        Pakyow.app.context = Context.new(mock_request, mock_response)
      end

      def test_fn_is_registered_and_fetchable
        set = RouteEval.new

        fn1 = lambda {}
        fn2 = lambda {}

        set.eval {
          fn(:foo, &fn1)
          fn(:bar, &fn2)
        }

        assert_same fn1, set.fn(:foo)
        assert_same fn2, set.fn(:bar)
      end

      def test_default_route_is_created_and_matched
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          default(fn1)
        }

        assert_route_tuple set.match('/', :get), ["", [], :default, fn1, ""]
      end

      def test_all_routes_are_created_and_matched
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}
        fn4 = lambda {}

        set.eval {
          get('get', fn1)
        }
        assert_route_tuple set.match('get', :get), ["get", [], nil, fn1, "get"]

        set.eval {
          post('post', fn2)
        }
        assert_route_tuple set.match('post', :post), ["post", [], nil, fn2, "post"]

        set.eval {
          put('put', fn3)
        }
        assert_route_tuple set.match('put', :put), ["put", [], nil, fn3, "put"]

        set.eval {
          delete('delete', fn4)
        }
        assert_route_tuple set.match('delete', :delete), ["delete", [], nil, fn4, "delete"]
      end

      def test_fn_list_can_be_passed_for_route
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          fn(:foo, &fn1)
          get('foo', fn(:foo))
        }

        assert_same fn1, set.match('foo', :get)[0][3][0]
      end

      def test_route_can_be_defined_without_fn
        set = RouteSet.new

        set.eval {
          get('foo')
        }

        assert !set.match('foo', :get).nil?
      end

      def test_single_fn_is_passable_to_route
        set = RouteSet.new

        set.eval {
          get('foo', lambda {})
        }
      end

      def test_keyed_routes_are_matched
        set = RouteSet.new

        set.eval {
          get(':id') {}
        }

        assert set.match('f/1', :get).nil?
        assert set.match('1', :post).nil?
        assert !set.match('1', :get).nil?
        assert !set.match('foo', :get).nil?

        set = RouteSet.new

        set.eval {
          get('foo/:id') {}
        }

        assert set.match('1', :get).nil?
        assert set.match('1', :post).nil?
        assert !set.match('foo/1', :get).nil?
        assert !set.match('foo/bar', :get).nil?
      end

      def test_route_vars_are_extracted_and_available_through_request
        rtr = Router.instance
        rtr.set(:test) {
          get(':id') { }
        }

        %w(1 foo).each { |data|
          context = Context.new(mock_request("/#{data}"))
          Router.instance.perform(context)
          assert_equal data, context.request.params[:id]
        }
      end

      def test_regexp_name_captures_are_extracted_and_available_through_request
        rtr = Router.instance
        rtr.set(:test) {
          get(/^foo\/(?<id>(\w|[-.~:@!$\'\(\)\*\+,;])*)$/) { }
        }

        %w(1 foo).each { |data|
          context = Context.new(mock_request("foo/#{data}"))
          Router.instance.perform(context)
          assert_equal data, context.request.params[:id]
        }
      end

      def test_routes_can_be_referenced_by_name
        set = RouteSet.new

        set.eval {
          get('foo', :foo) {}
        }

        assert !set.route(:foo).nil?
        assert set.route(:bar).nil?
      end

      def test_route_name_can_be_first_arg
        set = RouteSet.new

        set.eval {
          get(:foo, 'foo') {}
        }

        assert !set.route(:foo).nil?
        assert set.route(:bar).nil?
      end

      def test_handler_is_registered_and_matched
        set = RouteSet.new

        name = :err
        code = 500
        fn = lambda {}

        set.eval {
          handler(:err, 500, &fn)
        }

        assert_handler_tuple set.handle(name), [name, code, fn]
        assert_handler_tuple set.handle(code), [name, code, fn]
        assert set.handle(404).nil?
        assert set.handle(:nf).nil?
      end

      def test_hooks_can_be_added_to_route
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)
          get('1', fn(:fn1), before: fn(:fn2), after: fn(:fn3))
          get('2', fn(:fn1), after: fn(:fn3), before: fn(:fn2))
        }

        fns = set.match('1', :get)[0][3]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]

        fns = set.match('2', :get)[0][3]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_hooks_can_be_added_to_route_by_name
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)
          get('1', fn(:fn1), before: [:fn2], after: [:fn3])
        }

        fns = set.match('1', :get)[0][3]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_hooks_can_be_added_to_handler
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)
          handler(404, fn(:fn1), before: fn(:fn2), after: fn(:fn3))
          handler(401, fn(:fn1), after: fn(:fn3), before: fn(:fn2))
        }

        fns = set.handle(404)[2]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]

        fns = set.handle(401)[2]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_hooks_can_be_added_to_handler_by_name
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)
          handler(404, fn(:fn1), before: [:fn2], after: [:fn3])
        }

        fns = set.handle(404)[2]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_grouped_routes_can_be_matched
        set = RouteSet.new
        set.eval {
          group(:test_group) {
            default {}
          }
        }

        assert !set.match('/', :get).nil?
      end

      def test_grouped_routes_inherit_hooks
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)

          group(:test_group, before: fn(:fn2), after: fn(:fn3)) {
            default(fn(:fn1))
          }
        }

        fns = set.match('/', :get)[0][3]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_namespaced_routes_can_be_matched
        set = RouteSet.new

        set.eval {
          namespace('foo', :test_ns) {
            get('bar') {}
          }
        }

        assert !set.match('/foo/bar', :get).nil?
        assert set.match('/bar', :get).nil?
      end

      def test_namespaced_name_can_be_first_arg
        set = RouteSet.new

        set.eval {
          namespace(:test_ns, 'foo') {
            get('bar') {}
          }
        }

        assert !set.match('/foo/bar', :get).nil?
        assert set.match('/bar', :get).nil?
      end

      def test_namespaced_routes_inherit_hooks
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          fn(:fn1, &fn1)
          fn(:fn2, &fn2)
          fn(:fn3, &fn3)

          namespace('foo', :test_ns, before: fn(:fn2), after: fn(:fn3)) {
            default(fn(:fn1))
          }
        }

        fns = set.match('/foo', :get)[0][3]
        assert_same fn2, fns[0]
        assert_same fn1, fns[1]
        assert_same fn3, fns[2]
      end

      def test_route_templates_can_be_defined_and_expanded
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          template(:test_template) {
            get '/', :root
          }

          expand(:test_template, :test_expansion, 'foo') {
            action(:root, &fn1)
          }
        }

        assert_same fn1, set.match('/foo', :get)[0][3][0]
      end

      def test_route_templates_can_be_expanded_dynamically
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          template(:test_template) {
            get '/', :root
          }

          test_template(:test_expansion, 'foo') {
            root(&fn1)
          }
        }

        assert_same fn1, set.match('/foo', :get)[0][3][0]
      end

      def test_route_templates_can_define_hooks_for_actions
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          template(:test_template) {
            get '/', :root, before: fn1
          }

          test_template(:test_expansion, 'foo') {
            root(before: fn2, after: fn3)
          }
        }

        fns = set.match('/foo', :get)[0][3]

        assert_same fn1, fns[1]
        assert_same fn2, fns[0] # hooks defined in expansion have priority
        assert_same fn3, fns[2]
      end

      def test_route_templates_can_define_groups
        set = RouteSet.new

        set.eval {
          template(:test_template) {
            group :ima_group
          }

          test_template(:test_expansion, 'foo') {
            ima_group {
              get('grouped')
            }
          }
        }

        assert set.match('/foo/grouped', :get)
      end

      def test_route_template_groups_handle_hooks
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          template(:test_template) {
            group :ima_group, before: fn1
          }

          test_template(:test_expansion, 'foo') {
            ima_group(before: fn2, after: fn3) {
              get('grouped')
            }
          }
        }

        fns = set.match('/foo/grouped', :get)[0][3]

        assert_same fn1, fns[1]
        assert_same fn2, fns[0] # hooks defined in expansion have priority
        assert_same fn3, fns[2]
      end

      def test_route_templates_can_define_namespaces
        set = RouteSet.new

        set.eval {
          template(:test_template) {
            namespace :ima_namespace, 'ns'
          }

          test_template(:test_expansion, 'foo') {
            ima_namespace {
              get('namespaced')
            }
          }
        }

        assert set.match('/foo/ns/namespaced', :get)
      end

      def test_route_template_namespaces_handle_hooks
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}
        fn3 = lambda {}

        set.eval {
          template(:test_template) {
            namespace :ima_namespace, 'ns', before: fn1
          }

          test_template(:test_expansion, 'foo') {
            ima_namespace(before: fn2, after: fn3) {
              get('namespaced')
            }
          }
        }

        fns = set.match('/foo/ns/namespaced', :get)[0][3]

        assert_same fn1, fns[1]
        assert_same fn2, fns[0] # hooks defined in expansion have priority
        assert_same fn3, fns[2]
      end

      def test_routes_can_be_defined_in_template_expansion
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          template(:test_template) {
          }

          expand(:test_template, :test_expansion, 'foo') {
            get '/bar', fn1
          }
        }

        assert_same fn1, set.match('/foo/bar', :get)[0][3][0]
      end

      def test_templateception
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}

        set.eval {
          template(:test_template) {
            get '/', :root
          }

          expand(:test_template, :test_expansion, 'foo') {
            root fn1

            expand(:test_template, :nested_expansion, 'bar') {
              root fn2
            }
          }
        }

        assert_same fn1, set.match('/foo', :get)[0][3][0]
        assert_same fn2, set.match('/foo/bar', :get)[0][3][0]
      end

      def test_route_path_can_be_overridden
        set = RouteSet.new

        fn1 = lambda {}
        fn2 = lambda {}

        set.eval {
          template(:test_template) {
            routes_path { |path| File.join(path, 'bar') }

            get '/', :root
          }

          expand(:test_template, :test_expansion, 'foo') {
            get '/foo', fn1
            root fn2
          }
        }

        assert_same fn1, set.match('/foo/bar/foo', :get)[0][3][0]
        assert_same fn2, set.match('/foo/bar', :get)[0][3][0]
      end

      def test_nested_path_can_be_overridden
        set = RouteSet.new

        fn1 = lambda {}

        set.eval {
          template(:test_template) {
            nested_path { |path| File.join(path, 'nested') }

            get '/', :root
          }

          expand(:test_template, :test_expansion, 'foo') {
            expand(:test_template, :nested_expansion, 'bar') {
              root fn1
            }
          }
        }

        assert_same fn1, set.match('/foo/nested/bar', :get)[0][3][0]
      end

      private

      def assert_route_tuple(match, data)
        assert !match.nil?, "Route not found"
        return if match.nil?

        match = match[0]
        assert_equal data[0], match[0], "mismatched regex"
        assert_equal data[1], match[1], "mismatched vars"
        assert_equal data[2], match[2], "mismatched name"
        assert_equal data[3], match[3][0], "mismatched fn list"
        assert_equal data[4], match[4], "mismatched path"
      end

      def assert_handler_tuple(match, data)
        assert !match.nil?, "Handler not found"
        return if match.nil?

        assert_equal data[0], match[0], "mismatched name"
        assert_equal data[1], match[1], "mismatched code"
        assert_equal data[2], match[2][0], "mismatched fn list"
      end
    end
  end
end

