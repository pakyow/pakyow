require_relative 'support/helper'

describe StringDocRenderer do
  describe '#render' do
    let(:html) { '<div data-scope="foo" class="fooclass">foo</div><div data-scope="bar">bar</div>' }
    let(:structure) { StringDocParser.new(html).structure }

    it 'flattens structure into identical string' do
      expect(StringDocRenderer.render(structure)).to eq(html)
    end

    #TODO need many more test cases before I feel comfortable here
  end
end

