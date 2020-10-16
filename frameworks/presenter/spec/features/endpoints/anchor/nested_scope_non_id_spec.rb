RSpec.describe "presenting a view that defines an anchor endpoint in a nested scope whose parent does not use an id param" do
  include_context "app"

  context "binding is bound to" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts", param: :slug do
          show do
          end

          resource :comments, "/comments" do
            show do
              render "/presentation/endpoints/anchor/nested_scope"
            end
          end
        end

        presenter "/presentation/endpoints/anchor/nested_scope" do
          render :post do
            present(
              [
                { id: 1, title: "foo", slug: "foo", comments: [{ id: 1, title: "foo comment 1" }] },
                { id: 2, title: "bar", slug: "bar", comments: [{ id: 2, title: "bar comment 1" }, { id: 3, title: "bar comment 2" }] },
                { id: 3, title: "baz", slug: "baz", comments: [{ id: 4, title: "baz comment 1" }] }
              ]
            )
          end
        end
      end
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/nested_scope")[2]).to eq_sans_whitespace(
        <<~HTML
          <div data-b="post" data-id="1">
            <a href="/posts/foo" data-e="posts_show">
              view post
            </a>

            <h1 data-b="title">foo</h1>

            <div data-b="comment" data-id="1">
              <h2 data-b="title">foo comment 1</h2>

              <a href="/posts/foo/comments/1" data-e="posts_comments_show">
                view comment
              </a>
            </div>

            <script type="text/template" data-b="comment">
              <div data-b="comment"><h2 data-b="title">title</h2><a href="#" data-e="posts_comments_show">view comment</a></div>
            </script>
          </div>

          <div data-b="post" data-id="2">
            <a href="/posts/bar" data-e="posts_show">
              view post
            </a>

            <h1 data-b="title">bar</h1>

            <div data-b="comment" data-id="2">
              <h2 data-b="title">bar comment 1</h2>

              <a href="/posts/bar/comments/2" data-e="posts_comments_show">
                view comment
              </a>
            </div>

            <div data-b="comment" data-id="3">
              <h2 data-b="title">bar comment 2</h2>

              <a href="/posts/bar/comments/3" data-e="posts_comments_show">
                view comment
              </a>
            </div>

            <script type="text/template" data-b="comment">
              <div data-b="comment"><h2 data-b="title">title</h2><a href="#" data-e="posts_comments_show">view comment</a></div>
            </script>
          </div>

          <div data-b="post" data-id="3">
            <a href="/posts/baz" data-e="posts_show">
              view post
            </a>

            <h1 data-b="title">baz</h1>

            <div data-b="comment" data-id="4">
              <h2 data-b="title">baz comment 1</h2>

              <a href="/posts/baz/comments/4" data-e="posts_comments_show">
                view comment
              </a>
            </div>

            <script type="text/template" data-b="comment">
              <div data-b="comment"><h2 data-b="title">title</h2><a href="#" data-e="posts_comments_show">view comment</a></div>
            </script>
          </div>

          <script type="text/template" data-b="post">
            <div data-b="post"><a href="#" data-e="posts_show">view post</a><h1 data-b="title">title</h1><div data-b="comment"><h2 data-b="title">title</h2><a href="#" data-e="posts_comments_show">view comment</a></div></div>
          </script>
        HTML
      )
    end
  end
end
