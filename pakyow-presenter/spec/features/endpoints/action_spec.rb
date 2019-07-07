RSpec.describe "presenting a view that defines an endpoints with an action" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        def common
          expose :posts, [
            { id: 1, title: "foo" },
            { id: 2, title: "bar" },
            { id: 3, title: "baz" }
          ]

          render "/presentation/endpoints/action"
        end

        list do
          common
        end

        show do
          common
        end
      end
    end
  end

  it "sets the href on the action node" do
    expect(call("/posts")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-e="posts_show" data-id="1">
          <h1 data-b="title">foo</h1>
          <a href="/posts/1" data-e-a="">view post</a>
        </div>

        <div data-b="post" data-e="posts_show" data-id="2">
          <h1 data-b="title">bar</h1>
          <a href="/posts/2" data-e-a="">view post</a>
        </div>

        <div data-b="post" data-e="posts_show" data-id="3">
          <h1 data-b="title">baz</h1>
          <a href="/posts/3" data-e-a="">view post</a>
        </div>
      HTML
    )
  end

  context "endpoint is current" do
    it "adds a current class to the endpoint node" do
      expect(call("/posts/2")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-e="posts_show" data-id="1">
            <h1 data-b="title">foo</h1>
            <a href="/posts/1" data-e-a="">view post</a>
          </div>

          <div data-b="post" data-e="posts_show" data-id="2" class="ui-current">
            <h1 data-b="title">bar</h1>
            <a href="/posts/2" data-e-a="">view post</a>
          </div>

          <div data-b="post" data-e="posts_show" data-id="3">
            <h1 data-b="title">baz</h1>
            <a href="/posts/3" data-e-a="">view post</a>
          </div>
        HTML
      )
    end
  end

  context "presenter presents generally to the view" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          def common
            expose :posts, [
              { id: 1, title: "foo" },
              { id: 2, title: "bar" },
              { id: 3, title: "baz" }
            ]

            render "/presentation/endpoints/action"
          end

          list do
            common
          end

          show do
            common
          end
        end

        presenter "/presentation/endpoints/action" do
          render do
            find(:post).present(posts)
          end
        end
      end
    end

    it "sets the href on the action node" do
      expect(call("/posts")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-e="posts_show" data-id="1">
            <h1 data-b="title">foo</h1>
            <a href="/posts/1" data-e-a="">view post</a>
          </div>

          <div data-b="post" data-e="posts_show" data-id="2">
            <h1 data-b="title">bar</h1>
            <a href="/posts/2" data-e-a="">view post</a>
          </div>

          <div data-b="post" data-e="posts_show" data-id="3">
            <h1 data-b="title">baz</h1>
            <a href="/posts/3" data-e-a="">view post</a>
          </div>
        HTML
      )
    end
  end
end
