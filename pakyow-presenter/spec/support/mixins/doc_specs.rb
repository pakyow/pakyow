# All specs necessary to test a Doc (e.g. StringDoc / NokogiriDoc). Expects the
# Doc to provide the following via `let`:
#
# - doc: Doc representing a full document
# - node: Doc representing the first node of the full document
# - doctype: class name for Doc
#
shared_examples :doc_specs do
  describe 'doc' do
    let(:html) { '<div data-scope="foo" class="fooclass">foocontent <strong>strongtext</strong></div>' }

    describe '#set_attribute' do
      it 'changes the attribute value' do
        new_value = 'barclass'
        node.set_attribute(:class, new_value)
        expect(node.get_attribute(:class)).to eq(new_value)
      end
    end

    describe '#get_attribute' do
      it 'retrieves the attribute value' do
        expect(node.get_attribute(:class)).to eq('fooclass')
      end
    end

    describe '#remove_attribute' do
      it 'removes the attribute' do
        node.remove_attribute(:class)
        expect(node.get_attribute(:class)).to be_nil
      end
    end

    describe '#remove' do
      it 'removes the node' do
        doc.remove
        expect(doc.to_html).to eq('')
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
        expect(node.html).to eq('foocontent <strong>strongtext</strong>')
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
        node.append(' appended')
        expect(doc.text).to eq('foocontent strongtext appended')
      end

      it 'appends a doc' do
        doc.append(doctype.new(' appended'))
        expect(doc.text).to eq('foocontent strongtext appended')
      end
    end

    describe '#prepend' do
      it 'prepend content' do
        doc.prepend('prepended ')
        expect(doc.text).to eq('prepended foocontent strongtext')
      end

      it 'prepend a doc' do
        doc.prepend(doctype.new('prepended '))
        expect(doc.text).to eq('prepended foocontent strongtext')
      end
    end

    describe '#after' do
      it 'adds content after node' do
        after = 'after'
        node.after(after)
        expect(doc.to_html.gsub("\n", "")).to eq(html + after)
      end

      it 'adds doc after node' do
        after = 'after'
        node.after(doctype.new(after))
        expect(doc.to_html.gsub("\n", "")).to eq(html + after)
      end
    end

    describe '#before' do
      it 'adds content before node' do
        before = 'before'
        node.before(before)
        expect(doc.to_html.gsub("\n", "")).to eq(before + html)
      end

      it 'adds doc before node', focus: true do
        before = 'before'
        node.before(doctype.new(before))
        expect(doc.to_html.gsub("\n", "")).to eq(before + html)
      end
    end

    describe '#replace' do
      it 'replaces with content' do
        replacement = 'replaced'
        doc.replace(replacement)
        expect(doc.to_html).to eq(replacement)
      end

      it 'replaces with doc' do
        replacement = 'replaced'
        doc.replace(doctype.new(replacement))
        expect(doc.to_html).to eq(replacement)
      end
    end

    describe '#containers' do
      shared_examples :containers do
        describe 'unnamed container' do
          let(:doc) { doctype.new(unnamed_html) }

          it 'names the container `default`' do
            expect(doc.containers.has_key?(:default)).to be_truthy
          end

          it 'includes the container' do
            expect(doc.containers[:default][:doc].to_html).to eq('<!-- @container -->')
          end
        end

        describe 'named container' do
          let(:doc) { doctype.new(named_html) }

          it "names the container" do
            expect(doc.containers.has_key?(container_name)).to be_truthy
          end

          it 'includes the container node' do
            expect(doc.containers[container_name][:doc].to_html).to eq("<!-- @container #{container_name} -->")
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
      it "names the partial" do
        expect(doc.partials.has_key?(partial_name)).to be_truthy
      end

      it 'includes the partial node' do
        expect(doc.partials[partial_name].to_html).to eq("<!-- @include #{partial_name} -->")
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

        it 'includes nested scope in parent scope' do
          expect(doc.scopes[0][:nested].class).to eq(Array)
          expect(doc.scopes[0][:nested][0][:scope]).to eq(:bar)
        end
      end

      context 'when props are inline with scope' do
        #TODO is this something we still want to / can support?
      end

      context 'when props are in a nested scope' do
        let(:html) { '<div data-scope="foo"><div data-scope="bar"><div data-prop="bar"></div></div></div></div>' }

        it 'does not include nested props in parent scope' do
          expect(doc.scopes[0][:props].count).to eq(0)
        end
      end
    end
  end
end
