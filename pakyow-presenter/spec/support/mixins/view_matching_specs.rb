# Functional tests for view matching.

shared_examples :matching_specs do
  before do
    @original_doctype = Pakyow::Config.presenter.view_doc_class
    Pakyow::Config.presenter.view_doc_class = doctype
  end

  after do
    Pakyow::Config.presenter.view_doc_class = @original_doctype
  end

  describe 'matching a view with data' do
    let(:view) {
      Pakyow::Presenter::View.new(<<-D)
        <div data-scope="foo"></div>
      D
    }

    context 'when more data than views' do
      let(:data) { [0, 1, 2] }

      it 'results in one view per datum' do
        view.scope(:foo)[0].match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end

    context 'when data is an empty set' do
      let(:data) { [] }

      it 'results in an empty view' do
        view.scope(:foo)[0].match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end

    context 'when the view has a sibling' do
      let(:view) {
        Pakyow::Presenter::View.new(<<-D)
          <div data-scope="foo"></div><span>bar</span>
        D
      }

      let(:data) { [0, 1, 2] }

      it 'respects the original order of nodes' do
        view.scope(:foo)[0].match(data)
        expect(view.to_html.strip).to eq('<div data-scope="foo"></div><div data-scope="foo"></div><div data-scope="foo"></div><span>bar</span>')
      end
    end
  end

  describe 'matching a view collection with data' do
    let(:view) {
      Pakyow::Presenter::View.new(<<-D)
        <div data-scope="foo"></div>
        <div data-scope="foo"></div>
        <div data-scope="foo"></div>
      D
    }

    context 'when the same number of views and data' do
      let(:data) { [0, 1, 2] }

      it 'results in one view per datum' do
        view.scope(:foo).match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end

    context 'when more views than data' do
      let(:data) { [0, 1] }

      it 'results in one view per datum' do
        view.scope(:foo).match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end

    context 'when more data than views' do
      let(:data) { [0, 1, 2, 3, 4] }

      it 'results in one view per datum' do
        view.scope(:foo).match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end

    context 'when data is an empty set' do
      let(:data) { [] }

      it 'results in an empty view collection' do
        view.scope(:foo).match(data)
        expect(view.scope(:foo).length).to eq(data.length)
      end
    end
  end
end
