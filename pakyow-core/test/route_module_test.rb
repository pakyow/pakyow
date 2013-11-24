require 'pp'
require 'support/helper'

class TestClass; end

module TestFns
  include Pakyow::Routes
end

class MockEval
  def initialize
    @calls = []
  end

  def method_missing(name, *args)
    @calls << name
  end

  def called?(m)
    @calls.include?(m)
  end
end

class RouteModuleTest < Minitest::Test
  def setup
    Pakyow::App.stage(:test)
  end

  def test_errors_when_included_in_class
    assert_raises(StandardError) {
      TestClass.instance_exec { include Pakyow::Routes }
    }
  end

  def test_calls_are_forwarded_to_route_eval
    original_eval = TestFns.instance_variable_get(:@route_eval)

    eval = MockEval.new
    TestFns.instance_variable_set(:@route_eval, eval)

    %w(fn default get put post delete handler group namespace template action expand).each do |call|
      TestFns.send(call.to_sym)
      assert eval.called?(call.to_sym), "#{call} not called"
    end

    TestFns.instance_variable_set(:@route_eval, original_eval)
  end

  def test_route_modules_can_be_included_in_set
    @fns = {
      foo: lambda {}
    }

    TestFns.fn :foo, &@fns[:foo]

    Pakyow::App.routes :test do
      include TestFns
      include Pakyow::Routes::Restful
    end

    Pakyow.app.reload

    assert_same @fns[:foo], Pakyow::Router.instance.sets[:test].fn(:foo)
  end
end
