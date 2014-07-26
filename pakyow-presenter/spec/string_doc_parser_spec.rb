require_relative 'support/helper'

shared_examples :insignificant do
  it 'returns a structure with a single item' do
    expect(structure.length).to eq(1)
  end

  it 'returns a structure containing the entire document' do
    expect(structure[0]).to eq(html)
  end
end

describe StringDocParser do
  describe '#structure' do
    context 'parsing insignificant html' do
      context 'with no attributes' do
        let(:html) { '<div>foo</div>' }
        let(:structure) { StringDocParser.new(html).structure }

        include_examples :insignificant
      end

      context 'with attributes' do
        let(:html) { '<div class="fooclass">foo</div>' }
        let(:structure) { StringDocParser.new(html).structure }

        include_examples :insignificant
      end
    end

    context 'parsing significant html' do
      let(:html) { '<div data-scope="foo" class="fooclass">foo</div><div data-scope="bar">bar</div>' }
      let(:structure) { StringDocParser.new(html).structure }

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
            expect(last_structure[0][2][0]).to eq('foo')
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

  shared_examples :containers do
    describe 'unnamed container' do
      let(:parser) { StringDocParser.new(unnamed_html) }

      it 'names the container `default`' do
        expect(parser.containers.has_key?(:default)).to be_truthy
      end

      it 'includes the container' do
        expect(parser.containers[:default]).to eq('<!-- @container -->')
      end
    end

    describe 'named container' do
      let(:parser) { StringDocParser.new(named_html) }

      it "names the container" do
        expect(parser.containers.has_key?(container_name)).to be_truthy
      end

      it 'includes the container node' do
        expect(parser.containers[container_name]).to eq("<!-- @container #{container_name} -->")
      end
    end
  end

  describe '#containers' do
    context 'when container is top level' do
      let(:unnamed_html) { '<!-- @container -->' }
      let(:named_html) { '<!-- @container foo -->' }
      let(:container_name) { :foo }

      include_examples :containers
    end

    context 'when container is nested within significant node' do
      let(:unnamed_html) { '<div data-scope="foo"><!-- @container --></div>' }
      let(:named_html) { '<div data-scope="foo"><!-- @container foo --></div>' }
      let(:container_name) { :foo }

      include_examples :containers
    end

    context 'when container is nested within insignificant node' do
      let(:unnamed_html) { '<div><!-- @container --></div>' }
      let(:named_html) { '<div><!-- @container foo --></div>' }
      let(:container_name) { :foo }

      include_examples :containers
    end
  end

  shared_examples :partials do
    let(:parser) { StringDocParser.new(html) }

    it "names the partial" do
      expect(parser.partials.has_key?(partial_name)).to be_truthy
    end

    it 'includes the partial node' do
      expect(parser.partials[partial_name]).to eq("<!-- @include #{partial_name} -->")
    end
  end

  describe '#partials' do
    context 'when partial is top level' do
      let(:html) { '<!-- @include foo -->' }
      let(:partial_name) { :foo }
      include_examples :partials
    end

    context 'when partial is nested within significant node' do
      let(:html) { '<div data-scope="foo"><!-- @include foo --></div>' }
      let(:partial_name) { :foo }
      include_examples :partials
    end

    context 'when partial is nested within insignificant node' do
      let(:html) { '<div><!-- @include foo --></div>' }
      let(:partial_name) { :foo }
      include_examples :partials
    end
  end

  shared_examples :scopes_with_props do
    let(:parser) { StringDocParser.new(html) }

    it 'names the scope' do
      expect(parser.scopes.select { |s| s[:scope] == scope_name}.count ).to eq(1)
    end

    it 'includes the scope node' do
      expect(StringDocRenderer.render(parser.scopes[0][:doc])).to eq('<div data-scope="foo"><div data-prop="bar"></div></div>')
    end

    describe 'the scope\'s props' do
      it 'names the prop' do
        expect(parser.scopes[0][:props].count ).to eq(1)
      end

      it 'includes the prop node' do
        expect(StringDocRenderer.render(parser.scopes[0][:props][0][:doc])).to eq('<div data-prop="bar"></div>')
      end
    end
  end

  describe '#scopes' do
    context 'when scope is top level' do
      let(:html) { '<div data-scope="foo"><div data-prop="bar"></div></div>' }
      let(:scope_name) { :foo }
      include_examples :scopes_with_props
    end

    context 'when scope is nested within insignificant node' do
      let(:html) { '<div><div data-scope="foo"><div data-prop="bar"></div></div></div>' }
      let(:scope_name) { :foo }
      include_examples :scopes_with_props
    end

    context 'when scope is nested within scope' do
      let(:html) { '<div data-scope="foo"><div data-scope="bar"><div data-prop="bar"></div></div></div></div>' }
      let(:parser) { StringDocParser.new(html) }

      it 'includes nested scope in parent scope' do
        expect(parser.scopes[0][:nested].class).to eq(Array)
        expect(parser.scopes[0][:nested][0][:scope]).to eq(:bar)
      end
    end

    #TODO is this something we still want to support?
    # context 'when props are unscoped' do
    #   let(:html) { '<div data-prop="bar"></div>' }
    #   let(:parser) { StringDocParser.new(html) }

    #   it 'includes prop as unscoped' do
    #     expect(parser.scopes.count ).to eq(1)
    #   end
    # end

    context 'when props are inline with scope' do
      #TODO is this something we still want to / can support?
    end

    context 'when props are in a nested scope' do
      let(:html) { '<div data-scope="foo"><div data-scope="bar"><div data-prop="bar"></div></div></div></div>' }
      let(:parser) { StringDocParser.new(html) }

      it 'does not include nested props in parent scope' do
        expect(parser.scopes[0][:props].count).to eq(0)
      end
    end
  end
end
