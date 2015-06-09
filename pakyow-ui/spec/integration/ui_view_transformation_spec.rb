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

      expect(view.finalize).to eq([[:bind, [{ text: 'foo' }, { text: 'bar' }], [[:text, 'foo'], [:text, 'bar']]]])
    end
  end

  describe 'with a transformation that sets attributes' do
    it 'builds the proper instructions' do
      view.attrs.class.ensure :foo
      expect(view.finalize).to eq([[:attrs, nil, [[:class, nil, [[:ensure, :foo, []]]]]]])
    end
  end
end
