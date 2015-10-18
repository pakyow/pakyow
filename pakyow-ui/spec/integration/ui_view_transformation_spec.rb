require_relative 'support/int_helper'

describe 'transforming a ui view' do
  let :view do
    Pakyow::UI::UIView.new(scope)
  end

  let :scope do
    :post
  end

  describe 'with a transformation that does not expect a value' do
    it 'builds the proper instructions' do
      view.remove
      expect(view.finalize).to eq([[:remove, nil]])
    end
  end

  describe 'with a transformation that expects a value' do
    it 'builds the proper instructions' do
      view.text = 'foo'
      expect(view.finalize).to eq([[:text, 'foo']])
    end
  end

  describe 'with a transformation that changes the context' do
    it 'builds the proper instructions' do
      view.scope(:foo).remove
      expect(view.finalize).to eq([[:scope, 'foo', [[:remove, nil]]]])
    end
  end

  describe 'with a transformation that continues into another context' do
    it 'builds the proper instructions' do
      view.bind([{ text: 'foo' }, { text: 'bar' }]) do |view, datum|
        view.text = datum[:text]
      end

      expect(view.finalize).to eq([[:bind, [{ text: 'foo' }, { text: 'bar' }], [[[:text, 'foo']], [[:text, 'bar']]]]])
    end
  end

  describe 'with a transformation that sets attributes' do
    it 'builds the proper instructions' do
      view.attrs.class.ensure :foo
      expect(view.finalize).to eq([[:attrs, nil, [[:class, nil, [[:ensure, :foo, []]]]]]])
    end
  end

  describe 'with a transformation that sets attributes with hash syntax' do
    it 'builds the proper instructions' do
      view.attrs[:class] = :foo
      expect(view.finalize).to eq([[:attrs, nil, [[:class, :foo, []]]]])
    end
  end

  describe 'with a transformation that sets attributes with hash syntax and method' do
    it 'builds the proper instructions' do
      view.attrs[:class].ensure :foo
      expect(view.finalize).to eq([[:attrs, nil, [[:class, nil, [[:ensure, :foo, []]]]]]])
    end
  end

  describe 'with a transformation that invokes bindings' do
    describe 'and the binding returns a plain value' do
      it 'uses the new value' do
        view.bind({ text: 'foo' }, bindings: { text: lambda { |_value, _bindable, _context|
          'bar'
        } })

        expect(view.finalize).to eq([[:bind, [{ text: 'bar' }], []]])
      end
    end

    describe 'and the binding returns a hash' do
      it 'uses the content key for the value' do
        view.bind({ text: 'foo' }, bindings: { text: lambda { |_value, _bindable, _context|
          { content: 'bar' }
        } })

        expect(view.finalize).to eq([[:bind, [{ text: { __content: 'bar', __attrs: {} } }], []]])
      end

      it 'uses the other keys as attributes' do
        view.bind({ text: 'foo' }, bindings: { text: lambda { |_value, _bindable, _context|
          { content: 'bar', class: 'foo' }
        } })

        expect(view.finalize).to eq([[:bind, [{ text: { __content: 'bar', __attrs: { class: 'foo' } } }], []]])
      end

      describe 'and an attribute value is set in a block' do
        it 'properly evaluates the value' do
          view.bind({ text: 'foo' }, bindings: { text: lambda { |_value, _bindable, _context|
            { content: 'bar', class: ->(c) { c.ensure('foo') } }
          } })

          expect(view.finalize).to eq([[:bind, [{ text: { __content: 'bar', __attrs: { class: [[:ensure, 'foo', []]] } } }], []]])
        end
      end
    end
  end
end
