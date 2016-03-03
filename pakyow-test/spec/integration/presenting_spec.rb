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

  context 'and the view composition was changed' do
    context 'by using a different template' do
      let :template_name do
        :alternate
      end

      it 'exposes the composed template' do
        get :compose_template, with: { template: template_name } do |sim|
          expect(sim.view.template.name).to eq(template_name)
        end
      end
    end

    context 'by replacing a partial' do
      it 'exposes the composed partials'
    end
  end

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

  context 'and the route matches the view to data' do
    it 'appears to have matched scope to data'
  end

  context 'and the route repeats the view for data' do
    it 'appears to have repeated scope for data'
  end

  context 'and the route binds data to the view' do
    it 'appears to have bound data to the scope'

    context 'and the view contains a form field' do
      it 'appears to have bound data to the field'
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

    context 'and the data length is > 1' do
      let :data do
        [{ name: 'one' }, { name: 'two' }]
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
    end

    context 'and the applied scope is nested' do
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
  end

  context 'and the route manipulates the node of a view' do
    context 'by changing an attribute' do
      it 'appears that the attribute was changed' do
        get :attribute, with: { name: 'class', value: 'foo' } do |sim|
          expect(sim.view.scope(:post)[0].attrs.class.value).to eq(['foo'])
        end
      end
    end

    context 'by removing it' do
      it 'appears that the node was removed' do
        get :remove do |sim|
          expect(sim.view.scope(:post).exists?).to eq(false)
        end
      end
    end

    context 'by changing the text' do
      let :text do
        'test123'
      end

      it 'appears that the text was changed' do
        get :text, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.text).to eq(text)
        end
      end
    end

    context 'by changing the html' do
      let :html do
        '<span>some html</span>'
      end

      it 'appears that the html was changed' do
        get :html, with: { html: html } do |sim|
          expect(sim.view.scope(:post).first.html).to eq(html)
        end
      end
    end

    context 'by appending another view' do
      let :text do
        'to append'
      end

      let :view do
        Pakyow::Presenter::View.new(text)
      end

      it 'appears that the node was appended to' do
        get :append, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.appended?).to eq(true)
        end
      end

      it 'knows what was appended' do
        get :append, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.appended?(view)).to eq(true)
        end
      end
    end

    context 'by prepending another view' do
      let :text do
        'to prepend'
      end

      let :view do
        Pakyow::Presenter::View.new(text)
      end

      it 'appears that the node was prepended to' do
        get :prepend, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.prepended?).to eq(true)
        end
      end

      it 'knows what was prepended' do
        get :prepend, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.prepended?(view)).to eq(true)
        end
      end
    end

    context 'by adding another view after' do
      let :text do
        'to add after'
      end

      let :view do
        Pakyow::Presenter::View.new(text)
      end

      it 'appears that the node was added after' do
        get :after, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.after?).to eq(true)
        end
      end

      it 'knows what was added after' do
        get :after, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.after?(view)).to eq(true)
        end
      end
    end

    context 'by adding another node before' do
      let :text do
        'to add before'
      end

      let :view do
        Pakyow::Presenter::View.new(text)
      end

      it 'appears that the node was added before' do
        get :before, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.before?).to eq(true)
        end
      end

      it 'knows what was added before' do
        get :before, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.before?(view)).to eq(true)
        end
      end
    end

    context 'by replacing with another view' do
      let :text do
        'to replace'
      end

      let :view do
        Pakyow::Presenter::View.new(text)
      end

      it 'appears that the node was replaced' do
        get :replace, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.replaced?).to eq(true)
        end
      end

      it 'knows what was replaced' do
        get :replace, with: { text: text } do |sim|
          expect(sim.view.scope(:post).first.replaced?(view)).to eq(true)
        end
      end
    end
  end
end
