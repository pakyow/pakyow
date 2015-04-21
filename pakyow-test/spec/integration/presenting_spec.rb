require_relative 'support/int_helper'

context 'when testing a route that presents' do
  it 'appears to have presented the default view path' do
    get :default do |sim|
      expect(sim.presenter.path).to eq('/')
    end
  end

  context 'and the view path was changed' do
    it 'appears to have presented the new view path' do
      get :present, with: { path: 'sub' } do |sim|
        expect(sim.presenter.path).to eq('sub')
      end
    end
  end

  #TODO test custom composition stuff

  context 'and the view title was changed' do
    it 'exposes the title of the presented view' do
      get :title, with: { title: 'foo' } do |sim|
        expect(sim.view.title).to eq('foo')
      end
    end
  end

  context 'and the view contains a scope' do
    it 'appears to contain the scope' do
      get :scoped do |sim|
        expect(sim.view.scope?(:post)).to eq(true)
      end
    end
  end

  context 'and the view does not contain a scope' do
    it 'does not appear to contain the scope' do
      get :scoped do |sim|
        expect(sim.view.scope?(:foo)).to eq(false)
      end
    end
  end

  context 'and the route applies data to the view' do
    let :data do
      [{ name: 'one' }]
    end

    it 'appears to have bound data to the applied scope' do
      get :scoped, with: { data: data } do |sim|
        sim.view.scope(:post).with do |view|
          expect(view.applied?(data)).to eq(true)

          # checking for a specific value
          view.for(data) do |view, datum|
            expect(view.prop(:name).bound?(datum[:name])).to eq(true)
          end
        end
      end
    end

    it 'does not appear to have bound data to a non-applied scope' do
      get :scoped, with: { data: data } do |sim|
        expect(sim.view.scope(:other).applied?(data)).to eq(false)
      end
    end
  end

  context 'and the route applies data to nested scopes' do
    let :data do
      [
        {
          name: 'post one',
          comments: [
            { name: 'comment one' }
          ]
        }
      ]
    end

    it 'appears to have bound data to the nested scope' do
      get :nested, with: { data: data } do |sim|
        sim.view.scope(:post).with do |view|
          expect(view.applied?(data)).to eq(true)

          # checking for a specific value
          view.for(data) do |view, datum|
            expect(view.prop(:name).bound?(datum[:name])).to eq(true)
            expect(view.scope(:comment).applied?(datum[:comments])).to eq(true)
          end
        end
      end
    end

    it 'does not appear to have bound data to a non-nested scope of the same name' do
      get :nested, with: { data: data } do |sim|
        expect(sim.view.scope(:comment).applied?).to eq(false)
      end
    end
  end

  #TODO test these: with, for, match, repeat, bind

  context 'and the route manipulates the view' do
    context 'by changing an attribute' do
      it 'appears that the attribute was changed' do
        get :attribute, with: { name: 'class', value: 'foo' } do |sim|
          expect(sim.view.scope(:post)[0].attrs.class.value).to eq(['foo'])
        end
      end
    end

    context 'by removing a node' do
      it 'appears that the node was removed' do
        get :remove do |sim|
          expect(sim.view.scope(:post).exists?).to eq(false)
        end
      end
    end

    #TODO other view manipulations
  end
end
