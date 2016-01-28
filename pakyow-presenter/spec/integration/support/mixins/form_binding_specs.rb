shared_examples :form_binding_specs do
  let(:view) {
    Pakyow::Presenter::View.new(<<-D)
    <form data-scope="foo">
      <input data-prop="unnamed">
      <input data-prop="named" name="name">
      <input data-prop="unvalued">
      <input data-prop="valued" value="value">
      <input type="checkbox" data-prop="checked" value="value">
      <input type="radio" data-prop="checked_radio" value="value">
      <textarea data-prop="textarea"></textarea>
      <select data-prop="select"><option value="foo">foo</option><option value="bar">bar</option><option value="2">2</option></select>
    </form>
    D
  }

  context 'when binding to unnamed field' do
    it 'sets name attr' do
      view.scope(:foo).bind(unnamed: 'test')
      expect(view.scope(:foo).prop(:unnamed)[0].attrs.name.to_s).to eq('foo[unnamed]')
    end
  end

  context 'when binding to named field' do
    it 'does not set name attr' do
      view.scope(:foo).bind(named: 'test')
      expect(view.scope(:foo).prop(:named)[0].attrs.name.to_s).to eq('name')
    end
  end

  context 'when binding to unvalued field' do
    it 'sets value attr' do
      view.scope(:foo).bind(unvalued: 'test')
      expect(view.scope(:foo).prop(:unvalued)[0].attrs.value.to_s).to eq('test')
    end
  end

  context 'when binding to valued field' do
    it 'does not set value attr' do
      view.scope(:foo).bind(valued: 'test')
      expect(view.scope(:foo).prop(:valued)[0].attrs.value.to_s).to eq('value')
    end
  end

  context 'when binding to checkbox' do
    context 'and the value matches' do
      it 'sets checked' do
        view.scope(:foo).bind(checked: 'value')
        expect(view.scope(:foo).prop(:checked)[0].attrs.checked.value).to eq(true)
      end
    end
  end

  context 'when binding to radio button' do
    context 'and the value matches' do
      it 'sets checked' do
        view.scope(:foo).bind(checked_radio: 'value')
        expect(view.scope(:foo).prop(:checked_radio)[0].attrs.checked.value).to eq(true)
      end
    end
  end

  context 'when binding to textarea' do
    it 'sets value as content' do
      view.scope(:foo).bind(textarea: 'test')
      expect(view.scope(:foo).prop(:textarea)[0].text).to eq('test')
    end
  end

  context 'when binding to select' do
    context 'and the value matches an option value' do
      it 'selects the option' do
        view.scope(:foo).bind(select: 'foo')
        doc = Oga.parse_html(view.to_s)
        expect(doc.css('option')[0].attribute('selected').value).to eq('selected')
      end

      context 'and the value is not a string' do
        it 'selects the option' do
          view.scope(:foo).bind(select: 2)
          doc = Oga.parse_html(view.to_s)
          expect(doc.css('option')[2].attribute('selected').value).to eq('selected')
        end
      end
    end

    context 'and binding options are defined' do
      before do
        Pakyow::Presenter::Binder.instance.set(:default) do
          scope :foo do
            options :select do
              [[:one, 'one'], [:two, 'two']]
            end
          end
        end
      end

      after do
        Pakyow::Presenter::Binder.instance.reset
      end

      it 'creates options' do
        view.scope(:foo).bind(select: 'one')
        doc = Oga.parse_html(view.to_s)

        opts = doc.css('option')
        expect(opts.length).to eq(2)

        opt_1 = opts[0]
        opt_2 = opts[1]

        expect(opt_1.attribute('value').value).to eq('one')
        expect(opt_2.attribute('value').value).to eq('two')

        expect(opt_1.inner_text).to eq('one')
        expect(opt_2.inner_text).to eq('two')
      end

      context 'with default option' do
        before do
          Pakyow::Presenter::Binder.instance.set(:default) do
            scope :foo do
              options :select, empty: true do
                [[:one, 'one'], [:two, 'two']]
              end
            end
          end
        end

        after do
          Pakyow::Presenter::Binder.instance.reset
        end

        it 'sets default option' do
          view.scope(:foo).bind(select: 'one')
          doc = Oga.parse_html(view.to_s)

          opts = doc.css('option')
          expect(opts.length).to eq(3)

          opt_1 = opts[0]
          opt_2 = opts[1]
          opt_3 = opts[2]

          expect(opt_1.attribute('value').value).to eq('')
          expect(opt_2.attribute('value').value).to eq('one')
          expect(opt_3.attribute('value').value).to eq('two')

          expect(opt_1.inner_text).to eq('')
          expect(opt_2.inner_text).to eq('one')
          expect(opt_3.inner_text).to eq('two')
        end
      end
    end
  end
end
