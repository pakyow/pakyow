require 'support/helper'

class BindingsTest < Minitest::Test
  include ReqResHelpers

  def setup
    capture_stdout do
      Pakyow::App.stage(:test)
      Pakyow::Router.instance.set(:default) {
        expand(:restful, :bar, 'bar') {
          action(:create) {}
          action(:update) {}

          expand(:restful, :baz, 'baz') {
            action(:create) {}
            action(:update) {}
          }
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

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :action, {}, {}, Pakyow.app.context)

    assert_equal '/bar', data[:action]
    assert_equal 'post', data[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :action, { id: 1 }, {}, Pakyow.app.context)

    assert_equal '/bar/1',  data[:action]
    assert_equal 'post',    data[:method]

    view = View.from_doc(NokogiriDoc.from_doc(Nokogiri::HTML.fragment('')))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('input')[0]
    assert_equal 'hidden',  doc[:type]
    assert_equal '_method', doc[:name]
    assert_equal 'patch',     doc[:value]
  end

  def test_nested_restful_bindings_are_defined
    Pakyow.app.bindings {
      scope(:foo) {
        restful(:baz)
      }
    }

    capture_stdout do
      Pakyow.app.presenter.load
    end

    bar_id = 123
    Pakyow.app.context.request.params[:bar_id] = bar_id
    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :action, {}, {}, Pakyow.app.context)

    assert_equal "/bar/#{bar_id}/baz", data[:action]
    assert_equal 'post', data[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :action, { id: 1 }, {}, Pakyow.app.context)

    assert_equal "/bar/#{bar_id}/baz/1",  data[:action]
    assert_equal 'post',    data[:method]
  end
end
