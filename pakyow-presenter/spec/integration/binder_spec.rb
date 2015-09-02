require_relative 'support/int_helper'
include ReqResHelpers
include SetupHelper

describe Pakyow::Presenter::Binder do
  before :each do
    setup
  end

  after do
    teardown
  end

  it 'defines restful bindings' do
    Pakyow.app.bindings {
      scope(:foo) {
        restful(:bar)
      }
    }

    Pakyow.app.presenter.load

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, Pakyow.app.context)
    view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    expect('/bar').to eq doc[:action]
    expect('post').to eq doc[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, Pakyow.app.context)
    view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    form_doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    input_doc = Nokogiri::HTML.fragment(view.to_html).css('input')[0]
    expect('/bar/1').to eq form_doc[:action]
    expect('post').to eq form_doc[:method]
    expect('hidden').to eq input_doc[:type]
    expect('_method').to eq input_doc[:name]
    expect('patch').to eq input_doc[:value]
  end

  it 'defines nested restful bindings' do
    Pakyow.app.bindings {
      scope(:foo) {
        restful(:baz)
      }
    }
    Pakyow.app.presenter.load

    bar_id = 123
    Pakyow.app.context.request.params[:bar_id] = bar_id
    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, Pakyow.app.context)
    view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    expect("/bar/#{bar_id}/baz").to eq doc[:action]
    expect('post').to eq doc[:method]

    data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, Pakyow.app.context)
    view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
    data[:view].call(view)
    doc = Nokogiri::HTML.fragment(view.to_html).css('form')[0]
    expect("/bar/#{bar_id}/baz/1").to eq doc[:action]
    expect('post').to eq doc[:method]
  end
end
