# Functional tests for view building.

shared_examples :building_specs do
  before do
    @original_doctype = Pakyow::Config.presenter.view_doc_class
    Pakyow::Config.presenter.view_doc_class = doctype
  end

  after do
    Pakyow::Config.presenter.view_doc_class = @original_doctype
  end

  describe 'building a view with multiple instances of a partial' do
    let :view do
      Pakyow::Presenter::View.new(<<-D)
        <!-- @include some_partial -->
        <!-- @include some_partial -->
      D
    end

    let :partial do
      Pakyow::Presenter::Partial.new(<<-D)
        <div data-scope="foo">foo</div>
      D
    end

    let :composed do
      view.includes(some_partial: partial)
    end

    context 'modifying the partial' do
      it 'does not modify both instances' do
        composed.scope(:foo)[0].text = 'bar'
        expect(composed.scope(:foo)[0].text).to eq('bar')
        expect(composed.scope(:foo)[1].text).to eq('foo')
      end
    end
  end
end
