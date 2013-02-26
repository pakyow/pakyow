require 'support/helper'

class RoutingTest < MiniTest::Unit::TestCase
  attr_accessor :set_registered
  attr_accessor :fn_calls

  def setup
    @fn_calls = []
  end

  # RouteSet

  def test_fn_is_registered_and_fetchable
    set = RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.fn(:foo, &fn1)
    set.fn(:bar, &fn2)

    assert_same fn1, set.fn(:foo)[0]
    assert_same fn2, set.fn(:bar)[0]
  end

  def test_default_route_is_created_and_matched
    set = RouteSet.new

    fn1 = lambda {}
    set.default(fn1)
    assert_route_tuple set.match('/', :get), ["", [], :default, fn1, ""]
  end

  def test_all_routes_are_created_and_matched
    set = RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}
    fn4 = lambda {}
    
    set.get('get', fn1)
    assert_route_tuple set.match('get', :get), ["get", [], nil, fn1, "get"]

    set.post('post', fn2)
    assert_route_tuple set.match('post', :post), ["post", [], nil, fn1, "post"]

    set.put('put', fn3)
    assert_route_tuple set.match('put', :put), ["put", [], nil, fn1, "put"]

    set.delete('delete', fn4)
    assert_route_tuple set.match('delete', :delete), ["delete", [], nil, fn1, "delete"]
  end

  def test_fn_list_can_be_passed_for_route
    set = RouteSet.new

    fn1 = lambda {}
    set.fn(:foo, &fn1)
    set.get('foo', set.fn(:foo))

    assert_same fn1, set.match('foo', :get)[0][3][0]
  end

  def test_route_can_be_defined_without_fn
    set = RouteSet.new
    set.get('foo')

    assert !set.match('foo', :get).nil?
  end

  def test_keyed_routes_are_matched
    set = RouteSet.new
    set.get(':id') {}
    
    assert set.match('f/1', :get).nil?
    assert set.match('1', :post).nil?
    assert !set.match('1', :get).nil?
    assert !set.match('foo', :get).nil?

    set = RouteSet.new
    set.get('foo/:id') {}
    
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
      req = mock_request("/#{data}")
      Router.instance.route!(req)
      assert_equal data, req.params[:id]
    }
  end

  def test_routes_can_be_referenced_by_name
    set = RouteSet.new
    set.get('foo', :foo) {}

    assert !set.route(:foo).nil?
    assert set.route(:bar).nil?
  end

  def test_route_name_can_be_first_arg
    set = RouteSet.new
    set.get(:foo, 'foo') {}

    assert !set.route(:foo).nil?
    assert set.route(:bar).nil?
  end

  def test_handler_is_registered_and_matched
    set = RouteSet.new

    name = :err
    code = 500
    fn = lambda {}

    set.handler(:err, 500, &fn)

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

    set.fn(:fn1, &fn1)
    set.fn(:fn2, &fn2)
    set.fn(:fn3, &fn3)

    set.get('1', set.fn(:fn1), before: set.fn(:fn2), after: set.fn(:fn3))
    fns = set.match('1', :get)[0][3]
    assert_same fn2, fns[0]
    assert_same fn1, fns[1]
    assert_same fn3, fns[2]

    set.get('2', set.fn(:fn1), after: set.fn(:fn3), before: set.fn(:fn2))
    fns = set.match('2', :get)[0][3]
    assert_same fn2, fns[0]
    assert_same fn1, fns[1]
    assert_same fn3, fns[2]
  end

  def test_grouped_routes_can_be_matched
    set = RouteSet.new
    set.group(:test_group) {
      default {}
    }

    assert !set.match('/', :get).nil?
  end

  def test_grouped_routes_inherit_hooks
    set = RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.fn(:fn1, &fn1)
    set.fn(:fn2, &fn2)
    set.fn(:fn3, &fn3)

    set.group(:test_group, before: set.fn(:fn2), after: set.fn(:fn3)) {
      default(set.fn(:fn1))
    }

    fns = set.match('/', :get)[0][3]
    assert_same fn2, fns[0]
    assert_same fn1, fns[1]
    assert_same fn3, fns[2]
  end

  def test_namespaced_routes_can_be_matched
    set = RouteSet.new
    set.namespace('foo', :test_ns) {
      get('bar') {}
    }

    assert !set.match('/foo/bar', :get).nil?
    assert set.match('/bar', :get).nil?
  end

  def test_namespaced_name_can_be_first_arg
    set = RouteSet.new
    set.namespace(:test_ns, 'foo') {
      get('bar') {}
    }

    assert !set.match('/foo/bar', :get).nil?
    assert set.match('/bar', :get).nil?
  end

  def test_namespaced_routes_inherit_hooks
    set = RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.fn(:fn1, &fn1)
    set.fn(:fn2, &fn2)
    set.fn(:fn3, &fn3)

    set.namespace('foo', :test_ns, before: set.fn(:fn2), after: set.fn(:fn3)) {
      default(set.fn(:fn1))
    }

    fns = set.match('/foo', :get)[0][3]
    assert_same fn2, fns[0]
    assert_same fn1, fns[1]
    assert_same fn3, fns[2]
  end

  def test_route_templates_can_be_defined_and_expanded
    set = RouteSet.new
    set.template(:test_template) {
      get '/', :root, fn(:root)
    }

    fn1 = lambda {}
    set.fn(:fn1, &fn1)

    set.expand(:test_template, :test_expansion, 'foo') {
      action(:root, set.fn(:fn1))
    }

    assert_same fn1, set.match('/foo', :get)[0][3][0]
  end


  # Router
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
    assert Router.instance.route(:bar).nil?
  end

  def test_route_fns_called_in_order
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

      default fn(:one).concat(fn(:two)).concat(fn(:three))
    }

    Router.instance.route!(mock_request('/'))
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

    Router.instance.route!(mock_request('/'))
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

    Router.instance.route!(mock_request('/'))
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
    Pakyow.app.response = res
    Router.instance.route!(mock_request('/'))

    assert_equal [:handled], @fn_calls
    assert_equal 500, res.status
  end


  # RouteTemplate
  #TODO actions, namespaces are created, routes default/get/etc to set, map_actions, map_restful_actions

  
  # RouteLookup

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
    assert RouteLookup.new.path(:bar).nil?, "grouped route should only be available through group"
  end

  def test_namespaced_routes_can_be_looked_up_by_name_and_group
    rtr = Router.instance
    rtr.set(:test) {
      namespace('foo', :foo) {
        get('bar', :bar)
      }
    }

    assert_equal '/foo/bar', RouteLookup.new.group(:foo).path(:bar)
    assert RouteLookup.new.path(:bar).nil?, "grouped route should only be available through group"
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
