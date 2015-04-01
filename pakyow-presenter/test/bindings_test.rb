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

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, Pakyow.app.context)
    view = View.from_doc(StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    assert_equal '/bar',  doc[:action]
    assert_equal 'post', doc[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, Pakyow.app.context)
    view = View.from_doc(StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    form_doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    input_doc = Nokogiri::HTML.fragment(view.to_html).css('input')[0]
    assert_equal '/bar/1',  form_doc[:action]
    assert_equal 'post', form_doc[:method]
    assert_equal 'hidden',  input_doc[:type]
    assert_equal '_method', input_doc[:name]
    assert_equal 'patch',     input_doc[:value]
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
    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, Pakyow.app.context)
    view = View.from_doc(StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    assert_equal "/bar/#{bar_id}/baz", doc[:action]
    assert_equal 'post', doc[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, Pakyow.app.context)
    view = View.from_doc(StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    assert_equal "/bar/#{bar_id}/baz/1",  doc[:action]
    assert_equal 'post',    doc[:method]
  end
end
