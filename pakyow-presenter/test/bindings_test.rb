require 'support/helper'

class BindingsTest < MiniTest::Unit::TestCase
  def setup
    TestApplication.stage(:test)
    Pakyow::Router.instance.set(:default) {
      expand(:restful, :bar, 'bar') {
        action(:create) {}
        action(:update) {}
      }
    }
  end

  def test_restful_bindings_are_defined
    Pakyow.app.presenter.scope(:foo) {
      restful(:bar)
    }

    binding = View.binder_for_scope(:foo, {})
    data = binding.value_for_prop(:action)
    
    assert_equal '/bar', data[:action]
    assert_equal 'post', data[:method]

    binding = View.binder_for_scope(:foo, {id:1})
    data = binding.value_for_prop(:action)
    
    assert_equal '/bar/1',  data[:action]
    assert_equal 'post',    data[:method]

    doc = Nokogiri::HTML.fragment(data[:content].call('')).children[0]
    assert_equal 'hidden',  doc[:type]
    assert_equal '_method', doc[:name]
    assert_equal 'put',     doc[:value]
  end
end
