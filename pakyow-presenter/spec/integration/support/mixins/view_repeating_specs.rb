# Functional tests for view repetition.

RSpec.shared_examples :repeating_specs do
  before do
    @original_doctype = Pakyow::Config.presenter.view_doc_class
    Pakyow::App.config.presenter.view_doc_class = doctype
  end

  after do
    Pakyow::App.config.presenter.view_doc_class = @original_doctype
  end

  describe 'repeating a view collection with data' do
    context 'and the repeating view includes a partial' do
      let(:view) {
        Pakyow::Presenter::View.new(<<-D)
        <!-- @include partial -->
        D
      }

      let(:partial) {
        Pakyow::Presenter::Partial.new(<<-D)
        <div data-scope="foo">
          <div data-prop="value"></div>
        </div>
        D
      }

      it 'properly binds data to a scope found in the partial' do
        data = [
          { value: '1' },
          { value: '2' },
          { value: '3' },
        ]

        view.includes({ partial: partial })

        view.scope(:foo).repeat(data) do |datum|
          bind(datum)
        end

        view.scope(:foo).each_with_index do |subview, i|
          expect(subview.prop(:value)[0].text).to eq(data[i][:value].to_s)
        end
      end

      context 'and a nested scope' do
        let(:partial) {
          Pakyow::Presenter::Partial.new(<<-D)
          <div data-scope="foo">
            <div data-scope="bar">
              <div data-prop="value"></div>
            </div>
          </div>
          D
        }

        it 'properly binds data to the nested scope' do
          data = [
            { value: '1' },
            { value: '2' },
            { value: '3' },
          ]

          view.includes({ partial: partial })

          view.scope(:foo).repeat(data) do |datum|
            scope(:bar).bind(datum)
          end

          view.scope(:foo).each_with_index do |subview, i|
            expect(subview.scope(:bar).prop(:value)[0].text).to eq(data[i][:value].to_s)
          end
        end
      end
    end
  end
end
