# Functional tests for view building.
include ViewComposerHelpers

RSpec.shared_examples :building_specs do
  before do
    @store = Pakyow::Presenter::ViewStore.new(VIEW_PATH)
    @original_doctype = Pakyow::App.config.presenter.view_doc_class
    Pakyow::App.config.presenter.view_doc_class = doctype
  end

  after do
    Pakyow::App.config.presenter.view_doc_class = @original_doctype
  end

  describe 'building a view with multiple instances of a partial' do
    let :composer do
      compose_at('identical_partials')
    end

    let :composed do
      composer.composed
    end

    context 'modifying the partial on the uncomposed view' do
      it 'does not modify both instances' do
        composer.scope(:foo)[0].text = 'bar'
        composer.scope(:foo)[1].text = 'foo'
        expect(composed.scope(:foo)[0].text).to eq('bar')
        expect(composed.scope(:foo)[1].text).to eq('foo')
      end
    end

    context 'modifying the partial on the composed view' do
      it 'does not modify both instances' do
        composed.scope(:foo)[0].text = 'bar'
        composed.scope(:foo)[1].text = 'foo'
        expect(composed.scope(:foo)[0].text).to eq('bar')
        expect(composed.scope(:foo)[1].text).to eq('foo')
      end
    end
  end
end
