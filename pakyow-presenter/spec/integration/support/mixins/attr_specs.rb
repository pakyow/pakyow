shared_examples :attr_specs do
  describe 'attributes' do
    let :html do
      '<html><body><div data-scope="attrs"></div></body></html>'
    end

    let :view do
      Pakyow::Presenter::View.from_doc(doctype.new(html))
    end

    let :coll do
      view.scope(:attrs)
    end

    let :node do
      coll[0].dup
    end

    describe 'text attrs' do
      it 'sets a value' do
        value = 'foo'
        node.attrs.title = value
        expect(node.attrs.title.to_s).to eq(value)

        coll.attrs.title = value
        expect(coll.attrs.title.map { |a| a.to_s }).to eq([value])
      end

      it 'sets a value with hash syntax' do
        value = 'hfoo'
        node.attrs[:title] = value
        expect(node.attrs.title.to_s).to eq(value)

        coll.attrs[:title] = value
        expect(coll.attrs.title.map { |a| a.to_s }).to eq([value])
      end

      it 'appends a value' do
        value = 'foo'
        appended_value = 'bar'
        node.attrs.title = value.dup
        node.attrs.title << appended_value
        expect(node.attrs.title.to_s).to eq(value + appended_value)
      end

      it 'ensures a value' do
        value = 'foo'
        node.attrs.title.ensure(value)
        expect(node.attrs.title.to_s).to eq(value)

        # do it again
        node.attrs.title.ensure(value)
        expect(node.attrs.title.to_s).to eq(value)
      end

      it 'denies a value' do
        value = 'foo'
        node.attrs.title = value
        node.attrs.title.deny(value)
        expect(node.attrs.title.to_s).to eq('')
      end

      it 'deletes the value' do
        value = 'foobar'
        node.attrs.title = value
        node.attrs.title.delete!('bar')
        expect(node.attrs.title.to_s).to eq('foo')
        node.attrs.title.delete!('foo')
        expect(node.attrs.title.to_s).to eq('')
      end
    end

    describe 'enum attrs' do
      it 'sets a value' do
        value = 'foo'
        node.attrs.class = [value]
        expect(node.attrs.class.to_s).to eq(value)
        node.attrs.class = value
        expect(node.attrs.class.to_s).to eq(value)
      end
    end

    describe 'mult attrs' do
      it 'appends a value' do
        value = 'foo'
        appended_value = 'bar'
        node.attrs.class = value
        node.attrs.class << appended_value
        expect(node.attrs.class.to_s).to eq("#{value} #{appended_value}")

        coll.attrs.class = value
        coll.attrs.class << appended_value
        expect(coll.attrs.class.map(&:to_s)).to eq([[value, appended_value].join(' ')])
      end

      it 'ensures a value' do
        value = 'foo'
        node.attrs.class.ensure(value)
        expect(node.attrs.class.to_s).to eq(value)

        # do it again
        node.attrs.class.ensure(value)
        expect(node.attrs.class.to_s).to eq(value)
      end

      it 'denies a value' do
        value = 'foo'
        node.attrs.class << value
        node.attrs.class.deny(value)
        expect(node.attrs.class.to_s).to eq('')
      end

      it 'handles array methods' do
        value = 'foo'
        node.attrs.class.push(value)
        expect(node.attrs.class.to_s).to eq(value)
      end
    end

    describe 'bool attrs' do
      it 'sets a value' do
        node.attrs.disabled = true
        expect(node.attrs.disabled.value).to eq(true)
      end

      it 'ensures a value' do
        node.attrs.disabled.ensure(true)
        expect(node.attrs.disabled.value).to eq(true)
      end

      it 'denies a value' do
        node.attrs.disabled = true
        node.attrs.disabled.deny(true)
        expect(node.attrs.disabled.value).to eq(false)
      end
    end

    describe 'hash attrs' do
      it 'sets a value' do
        node.attrs.style[:color] = 'red'
        expect(node.attrs.style.to_s).to eq('color:red')

        node.attrs.style = { color:'blue' }
        expect(node.attrs.style.to_s).to eq('color:blue')
      end
    end

    it 'assigns value en masse' do
      hash = { title: 'foo', class: 'bar' }

      node.attrs(hash)
      expect(node.attrs.title.to_s).to eq(hash[:title])
      expect(node.attrs.class.to_s).to eq(hash[:class])
    end

    it 'modifies values with lambdas' do
      node.attrs.title = 'foo'
      node.attrs.title = lambda {|t| t + 'bar'}
      expect(node.attrs.title.to_s).to eq('foobar')

      node.attrs.class = 'foo'
      node.attrs.class = lambda {|c| c.push('bar')}
      expect(node.attrs.class.to_s).to eq('foo bar')
    end
  end
end
