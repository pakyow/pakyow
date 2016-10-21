RSpec.shared_examples :scope_specs do
  describe 'scope' do
    let(:view) {
      string = <<-D
      <div data-scope="post">
        <h1 data-prop="title">title</h1>
        <div>
          <p data-prop="body">body</p>
        </div>
        <div data-scope="comment"></div>
        <div data-scope="comment"></div>
      </div>
      D

      Pakyow::Presenter::View.from_doc(doctype.new(string))
    }

    it 'finds single scope' do
      expect(view.scope(:post).length).to eq(1)
      expect(view.scope('post').length).to eq(1)
    end

    it 'finds multiple scopes' do
      expect(view.scope(:post).scope(:comment).length).to eq(2)
    end

    it 'finds nested scopes' do
      expect(view.scope(:comment).length).to eq(0)
      expect(view.scope(:post).length).to eq(1)
      expect(view.scope(:post).scope(:comment).length).to eq(2)
    end

    it 'ignores invalid scopes' do
      expect(view.scope(:fail).length).to eq(0)
    end

    it 'finds props' do
      expect(view.scope(:post).prop(:title)[0].html).to eq('title')
      expect(view.scope(:post).prop(:body)[0].html).to eq('body')
    end

    it 'does not nest scope within itself' do
      post_binding = view.doc.scopes.first
      post_binding[:nested].each {|nested|
        expect(nested[:doc]).not_to eq(post_binding[:doc])
      }
    end

    context 'when there is an unused partial in the path' do
      let :view do
        Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::ViewComposer.from_path(store, 'scope_with_unused_partial'), {})
      end

      let :data do
        { name: 'foo' }
      end

      it 'binds data to the scope' do
        view = Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::ViewComposer.from_path(Pakyow::Presenter::ViewStore.new(VIEW_PATH), 'scope_with_unused_partial'), {})
        expect(view.scope(:article).instance_variable_get(:@view).views.count).to eq(1)
      end
    end

    context 'when there is insignificant html after the scope' do
      let(:view) {
        string = <<-D
        <div data-scope="post">
          foo
        </div>
        <span>
          bar
        </span>
        D

        Pakyow::Presenter::View.from_doc(doctype.new(string))
      }

      context 'and the scope is removed' do
        let :scope do
          view.scope(:post)[0]
        end

        before do
          scope.remove
        end

        it 'appears to not exist' do
          expect(scope.exists?).to be(false)
        end

        it 'is empty' do
          expect(scope.to_html).to eq('')
        end

        context 'and a node is appended' do
          before do
            scope.doc.append('bar')
          end

          it 'appends the node' do
            expect(scope.doc.to_html).to eq('bar')
          end
        end
      end
    end
  end
end
