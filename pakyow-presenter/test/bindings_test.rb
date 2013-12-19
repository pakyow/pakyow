require 'support/helper'

class BindingsTest < Minitest::Test
  def setup
    capture_stdout do
      Pakyow::App.stage(:test)
      Pakyow::Router.instance.set(:default) {
        expand(:restful, :bar, 'bar') {
          action(:create) {}
          action(:update) {}
        }
      }

      Pakyow.app.context = AppContext.new(mock_request, mock_response)
    end
  end

  def test_restful_bindings_are_defined
    Pakyow.app.bindings {
      scope(:foo) {
        restful(:bar)
      }
    }

    capture_stdout do
      Pakyow.app.presenter.load
    end

    data = Pakyow.app.presenter.binder.value_for_prop(:action, :foo, {}, Pakyow.app.context)

    assert_equal '/bar', data[:action]
    assert_equal 'post', data[:method]

    data = Pakyow.app.presenter.binder.value_for_prop(:action, :foo, {id:1}, Pakyow.app.context)

    assert_equal '/bar/1',  data[:action]
    assert_equal 'post',    data[:method]

    view = View.from_doc(Nokogiri::HTML.fragment(''))
    data[:view].call(view)
    doc = view.doc.children[0]
    assert_equal 'hidden',  doc[:type]
    assert_equal '_method', doc[:name]
    assert_equal 'put',     doc[:value]
  end
end
