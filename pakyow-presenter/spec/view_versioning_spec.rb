require_relative 'support/helper'

describe ViewVersion do
  let :store do
    ViewStore.new(VIEW_PATH)
  end

  let :versioned do
    ViewContext.new(ViewComposer.from_path(store, 'versioned'), {})
  end

  let :empty do
    ViewContext.new(ViewComposer.from_path(store, 'versioned/empty'), {})
  end

  let :default do
    ViewContext.new(ViewComposer.from_path(store, 'versioned/default'), {})
  end

  let :view do
    context.view.instance_variable_get(:@view)
  end

  context 'when applying an empty dataset' do
    before do
      context.scope(:post).apply(data)
    end

    let :data do
      []
    end

    context 'and there is no empty version' do
      let :context do
        versioned
      end

      it 'renders nothing' do
        expect(context.view.scope(:post).length).to eq(0)
      end
    end

    context 'and there is an empty version' do
      let :context do
        empty
      end

      it 'renders the empty version' do
        expect(view.scope(:post).first.version).to eq(:empty)
      end
    end
  end

  context 'when applying a non-empty dataset' do
    let :data do
      [
        { title: 't-1', body: 'b-1', version: :two },
        { title: 't-2', body: 'b-2', version: :one },
        { title: 't-3', body: 'b-3', version: :one }
      ]
    end

    let :context do
      empty
    end

    context 'and the version is not specified' do
      before do
        context.scope(:post).apply(data)
      end

      context 'and there is no default version' do
        let :context do
          empty
        end

        it 'renders the first non-empty version for each datum' do
          expect(view.scope(:post)[0].version).to eq(:one)
          expect(view.scope(:post)[1].version).to eq(:one)
          expect(view.scope(:post)[2].version).to eq(:one)
        end
      end

      context 'and there is a default version' do
        let :context do
          default
        end

        it 'renders the default version for each datum' do
          expect(view.scope(:post)[0].version).to eq(:two)
          expect(view.scope(:post)[1].version).to eq(:two)
          expect(view.scope(:post)[2].version).to eq(:two)
        end
      end
    end

    context 'and the version is specified' do
      let :context do
        empty
      end

      before do
        context.scope(:post).version(data) { |view, datum|
          view.use(datum[:version])
        }.bind(data)
      end

      it 'renders the specified version for each datum' do
        expect(view.scope(:post)[0].version).to eq(:two)
        expect(view.scope(:post)[1].version).to eq(:one)
        expect(view.scope(:post)[2].version).to eq(:one)
      end
    end
  end
end
