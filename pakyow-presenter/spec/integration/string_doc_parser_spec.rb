require_relative 'support/int_helper'

shared_examples :insignificant do
  it 'returns a structure with a single item' do
    expect(structure.length).to eq(1)
  end

  it 'returns an appendable structure' do
    expect(structure[0][2].length).to eq(2)
  end
end

describe Pakyow::Presenter::StringDocParser do
  describe '#structure' do
    context 'parsing insignificant html' do
      context 'with no attributes' do
        let(:html) { '<div>foo</div>' }
        let(:structure) { Pakyow::Presenter::StringDocParser.new(html).structure }

        include_examples :insignificant
      end

      context 'with attributes' do
        let(:html) { '<div class="fooclass">foo</div>' }
        let(:structure) { Pakyow::Presenter::StringDocParser.new(html).structure }

        include_examples :insignificant
      end
    end

    context 'parsing significant html' do
      let(:html) { '<div data-scope="foo" class="fooclass">foo</div><div data-scope="bar">bar</div>' }
      let(:structure) { Pakyow::Presenter::StringDocParser.new(html).structure }

      it 'returns a structure with one item per significant node' do
        expect(structure.length).to eq(2)
      end

      it 'breaks the significant node into separate parts' do
        expect(structure[0].length).to eq(3)
      end

      describe 'structure for each significant node' do
        let(:significant_structure) { structure[0] }

        it 'includes the opening tag' do
          expect(significant_structure[0]).to eq('<div ')
        end

        it 'includes each attribute' do
          expect(significant_structure[1][:'data-scope']).to eq('foo')
          expect(significant_structure[1][:class]).to eq('fooclass')
        end

        describe 'structure after attributes' do
          let(:last_structure) { significant_structure[2] }

          it 'includes the closing bracket for the opening tag' do
            expect(last_structure[0][0]).to eq('>')
          end

          it 'includes the content' do
            expect(last_structure[0][2][0][0]).to eq('foo')
          end

          it 'includes the closing tag' do
            expect(last_structure[1][0]).to eq('</div>')
          end
        end
      end
    end

    describe 'html with nested significant nodes' do
      #TODO
    end
  end

end

