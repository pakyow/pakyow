require_relative 'support/int_helper'
include ReqResHelpers
include SetupHelper

RSpec.describe Pakyow::Presenter::Binder do
  include Pakyow::Support::Silenceable

  before :each do
    setup
  end

  after do
    teardown
  end

  it 'defines restful bindings' do
    silence_warnings do
      Pakyow.app.bindings {
        scope(:foo) {
          restful(:bar)
        }
      }

      Pakyow.app.presenter.load

      data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, @context)
      view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
      data[:view].call(view)

      doc = Oga.parse_xml(view.to_html).css('form')[0]
      expect('/bar').to eq doc.attribute(:action).value
      expect('post').to eq doc.attribute(:method).value

      data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, @context)
      view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
      data[:view].call(view)
      form_doc = Oga.parse_xml(view.to_html).css('form')[0]
      input_doc = Oga.parse_xml(view.to_html).css('input')[0]
      expect('/bar/1').to eq form_doc.attribute(:action).value
      expect('post').to eq form_doc.attribute(:method).value
      expect('hidden').to eq input_doc.attribute(:type).value
      expect('_method').to eq input_doc.attribute(:name).value
      expect('patch').to eq input_doc.attribute(:value).value
    end
  end

  it 'defines nested restful bindings' do
    silence_warnings do
      Pakyow.app.bindings {
        scope(:foo) {
          restful(:baz)
        }
      }
      Pakyow.app.presenter.load

      bar_id = 123
      @context.request.params[:bar_id] = bar_id
      data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, {}, {}, @context)
      view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
      data[:view].call(view)
      doc = Oga.parse_xml(view.to_html).css('form')[0]
      expect("/bar/#{bar_id}/baz").to eq doc.attribute(:action).value
      expect('post').to eq doc.attribute(:method).value

      data = Pakyow.app.presenter.binder.value_for_scoped_prop(:foo, :_root, { id: 1 }, {}, @context)
      view = Pakyow::Presenter::View.from_doc(Pakyow::Presenter::StringDoc.new('<form data-scope="foo"></form>'))
      data[:view].call(view)
      doc = Oga.parse_xml(view.to_html).css('form')[0]
      expect("/bar/#{bar_id}/baz/1").to eq doc.attribute(:action).value
      expect('post').to eq doc.attribute(:method).value
    end
  end
end
