RSpec.describe "presenting a view that defines an anchor endpoint in a nested scope" do
  include_context "app"

  context "binding is bound to" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          resource :comments, "/comments" do
            show do
              render "/presentation/endpoints/anchor/nested_scope"
            end
          end
        end

        presenter "/presentation/endpoints/anchor/nested_scope" do
          render :post do
            present(id: 1, title: "foo", comments: [{ id: 2, title: "bar" }])
          end
        end
      end
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/nested_scope")[2]).to include_sans_whitespace(
        <<~HTML
          <a href="/posts/1/comments/2" data-e="posts_comments_show">
            view comment
          </a>
        HTML
      )
    end

    context "endpoint is current" do
      it "receives a current class" do
        expect(call("/posts/1/comments/2")[2]).to include_sans_whitespace(
          <<~HTML
            <a href="/posts/1/comments/2" data-e="posts_comments_show" class="current">
              view comment
            </a>
          HTML
        )
      end
    end
  end
end
