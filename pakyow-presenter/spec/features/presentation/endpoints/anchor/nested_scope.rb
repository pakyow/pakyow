RSpec.describe "presenting a view that defines an anchor endpoint in a nested scope" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)
    }
  end

  context "binding is bound to" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        resources :posts, "/posts" do
          resources :comments, "/comments" do
            show do
              render "/presentation/endpoints/anchor/nested_scope"
            end
          end
        end

        presenter "/presentation/endpoints/anchor/nested_scope" do
          find(:post).present(id: 1, title: "foo", comments: [{ id: 2, title: "bar" }])
        end
      }
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/nested_scope")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <a href="/posts/1/comments/2">
            view comment
          </a>
        HTML
      )
    end

    context "endpoint is current" do
      it "receives an active class" do
        expect(call("/posts/1/comments/2")[2].body.read).to include_sans_whitespace(
          <<~HTML
            <a href="/posts/1/comments/2" class="active">
              view comment
            </a>
          HTML
        )
      end
    end
  end
end
