require_relative 'support/helper'

#TODO test that containers, partials, scopes reference same nodes? so that when
# one is modified it modifies the other?

describe StringDoc do
  let(:html) { '<div data-scope="foo" class="fooclass">foocontent <strong>strongtext</strong></div>' }
  let(:doc) { StringDoc.new(html) }

  describe '#initialize' do
    it 'parses html with StringDocParser' do
      skip
    end

    it 'sets instance variables with values from parser' do
      skip
    end
  end

  describe '#set_attribute' do
    it 'changes the attribute value' do
      new_value = 'barclass'
      doc.set_attribute(:class, new_value)
      expect(doc.get_attribute(:class)).to eq(new_value)
    end
  end

  describe '#get_attribute' do
    it 'retrieves the attribute value' do
      expect(doc.get_attribute(:class)).to eq('fooclass')
    end
  end

  describe '#remove_attribute' do
    it 'removes the attribute' do
      doc.remove_attribute(:class)
      expect(doc.get_attribute(:class)).to be_nil
    end
  end

  describe '#remove' do
    it 'removes the node' do
      doc.remove
      expect(doc).to eq('')
    end
  end

  describe '#clear' do
    it 'removes all content' do
      doc.clear
      expect(doc.html).to eq('')
    end
  end

  describe '#text' do
    it 'returns text content' do
      expect(doc.text).to eq('foocontent strongtext')
    end
  end

  describe '#text=' do
    it 'sets text content' do
      doc.text = 'replaced'
      expect(doc.text).to eq('replaced')
    end
  end

  describe '#html' do
    it 'returns html content' do
      expect(doc.html).to eq('foocontent <strong>strongtext</strong>')
    end
  end

  describe '#html=' do
    it 'sets html content' do
      doc.html = '<p>replaced</p>'
      expect(doc.html).to eq('<p>replaced</p>')
    end
  end

  describe '#append' do
    it 'appends content' do
      doc.append(' appended')
      expect(doc.text).to eq('foocontent strongtext appended')
    end

    it 'appends a StringDoc' do
      doc.append(StringDoc.new(' appended'))
      expect(doc.text).to eq('foocontent strongtext appended')
    end
  end

  describe '#prepend' do
    it 'prepend content' do
      doc.prepend('prepended ')
      expect(doc.text).to eq('prepended foocontent strongtext')
    end

    it 'prepend a StringDoc' do
      doc.prepend(StringDoc.new('prepended '))
      expect(doc.text).to eq('prepended foocontent strongtext')
    end
  end

  describe '#after' do
    it 'adds content after node' do
      after = 'after'
      doc.after(after)
      expect(doc.to_html).to eq(html + after)
    end

    it 'adds StringDoc after node' do
      after = 'after'
      doc.after(StringDoc.new(after))
      expect(doc.to_html).to eq(html + after)
    end
  end

  describe '#before' do
    it 'adds content before node' do
      before = 'before'
      doc.before(before)
      expect(doc.to_html).to eq(before + html)
    end

    it 'adds StringDoc before node', focus: true do
      before = 'before'
      doc.before(StringDoc.new(before))
      expect(doc.to_html).to eq(before + html)
    end
  end

	describe '#replace' do
		it 'replaces with content' do
			replacement = 'replaced'
			doc.replace(replacement)
			expect(doc.to_html).to eq(replacement)
		end

		it 'replaces with StringDoc' do
			replacement = 'replaced'
			doc.replace(StringDoc.new(replacement))
			expect(doc.to_html).to eq(replacement)
		end
	end

  describe '#containers' do
    shared_examples :containers do
      describe 'unnamed container' do
        let(:doc) { StringDoc.new(unnamed_html) }

        it 'names the container `default`' do
          expect(doc.containers.has_key?(:default)).to be_truthy
        end

        it 'includes the container' do
          expect(doc.containers[:default][:doc]).to eq('<!-- @container -->')
        end
      end

      describe 'named container' do
        let(:doc) { StringDoc.new(named_html) }

        it "names the container" do
          expect(doc.containers.has_key?(container_name)).to be_truthy
        end

        it 'includes the container node' do
          expect(doc.containers[container_name][:doc]).to eq("<!-- @container #{container_name} -->")
        end
      end
    end

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
    let(:doc) { StringDoc.new(html) }

    it "names the partial" do
      expect(doc.partials.has_key?(partial_name)).to be_truthy
    end

    it 'includes the partial node' do
      expect(doc.partials[partial_name]).to eq("<!-- @include #{partial_name} -->")
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
    let(:doc) { StringDoc.new(html) }

    it 'names the scope' do
      expect(doc.scopes.select { |s| s[:scope] == scope_name}.count ).to eq(1)
    end

    it 'includes the scope node' do
      expect(doc.scopes[0][:doc].to_html).to eq('<div data-scope="foo"><div data-prop="bar"></div></div>')
    end

    describe 'the scope\'s props' do
      it 'names the prop' do
        expect(doc.scopes[0][:props].count ).to eq(1)
      end

      it 'includes the prop node' do
        expect(doc.scopes[0][:props][0][:doc].to_html).to eq('<div data-prop="bar"></div>')
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
      let(:doc) { StringDoc.new(html) }

      it 'includes nested scope in parent scope' do
        expect(doc.scopes[0][:nested].class).to eq(Array)
        expect(doc.scopes[0][:nested][0][:scope]).to eq(:bar)
      end
    end

    #TODO is this something we still want to support?
    # context 'when props are unscoped' do
    #   let(:html) { '<div data-prop="bar"></div>' }
    #   let(:doc) { StringDoc.new(html) }

    #   it 'includes prop as unscoped' do
    #     expect(doc.scopes.count ).to eq(1)
    #   end
    # end

    context 'when props are inline with scope' do
      #TODO is this something we still want to / can support?
    end

    context 'when props are in a nested scope' do
      let(:html) { '<div data-scope="foo"><div data-scope="bar"><div data-prop="bar"></div></div></div></div>' }
      let(:doc) { StringDoc.new(html) }

      it 'does not include nested props in parent scope' do
        expect(doc.scopes[0][:props].count).to eq(0)
      end
    end
  end
end

