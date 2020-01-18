RSpec.describe "presenting a view that defines an endpoint for delete" do
  include_context "app"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        show do
          expose :post, { id: 1, title: "foo" }
          render "/presentation/endpoints/delete"
        end

        delete do; end
      end
    end
  end

  def postprocess(html)
    html.gsub!(/<input type="hidden" name="pw-form" value="([^"])*">/, '<input type="hidden" name="pw-form">')
    html
  end

  it "wraps the node in a form" do
    expect(postprocess(call("/posts/1")[2])).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-id="1">
          <h1 data-b="title">foo</h1>

          <form action="/posts/1" method="post">
            <input type="hidden" name="pw-form">
            <input type="hidden" name="pw-http-method" value="delete">
            <button>delete</button>
          </form>
        </div>

        <script type="text/template" data-b="post">
          <div data-b="post">
            <h1 data-b="title"></h1>
            <button data-e="posts_delete">delete</button>
          </div>
        </script>
      HTML
    )
  end

  context "node is a link" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          show do
            expose :post, { id: 1, title: "foo" }
            render "/presentation/endpoints/delete/link"
          end

          delete do; end
        end
      end
    end

    it "clears the href" do
      expect(postprocess(call("/posts/1")[2])).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-id="1">
            <h1 data-b="title">foo</h1>

            <form action="/posts/1" method="post">
              <input type="hidden" name="pw-form">
              <input type="hidden" name="pw-http-method" value="delete">
              <a href="javascript:void(0)" class="ui-current">delete</a>
            </form>
          </div>

          <script type="text/template" data-b="post">
            <div data-b="post">
              <h1 data-b="title"></h1>
              <a href="/foo/bar" data-e="posts_delete">delete</a>
            </div>
          </script>
        HTML
      )
    end
  end
end
