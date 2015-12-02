require_relative 'support/int_helper'
include ViewComposerHelpers

describe 'traversing through a partial' do
  before do
    @store = Pakyow::Presenter::ViewStore.new(VIEW_PATH)
  end

  context 'when finding a scope' do
    context 'and the scope is defined in the page' do
      context 'and the prop is defined in an included partial' do
        let :view do
          compose_at('partial_traversal')
        end

        let :partial do
          view.partial(:partial_one)
        end

        it 'finds the prop' do
          expect(partial.scope(:foo).prop(:bar)[0]).not_to eq(nil)
        end

        context 'and data is bound to the scope' do
          let :datum do
            { bar: 'one' }
          end

          before do
            partial.scope(:foo).bind(datum)
          end

          describe 'the composed view' do
            it 'contains the bound value' do
              expect(view.scope(:foo).prop(:bar)[0].text).to eq datum[:bar]
            end
          end
        end
      end
    end
  end
end
