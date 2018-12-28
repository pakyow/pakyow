RSpec.describe "presenting a view that defines an anchor endpoint that needs additional context" do
  include_context "app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resource :posts, "/posts" do
        show do
          render "/presentation/endpoints/anchor/contextual"
        end
      end
    }
  end

  it "builds the action using request params as context" do
    expect(call("/posts/1")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <a href="/posts/1" data-e="posts_show" class="current"></a>
      HTML
    )
  end

  context "endpoint node is within a binding" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        resource :posts, "/posts" do
          show do
            render "/presentation/endpoints/anchor/contextual/within_binding"
          end
        end

        presenter "/presentation/endpoints/anchor/contextual/within_binding" do
          def perform
            find(:post).bind(id: 3, title: "foo")
          end
        end
      }
    end

    it "builds the action using binding as context" do
      expect(call("/posts/1")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-id="3">
            <h1 data-b="title">foo</h1>

            <a href="/posts/3" data-e="posts_show">View</a>
          </div>
        HTML
      )
    end
  end

  context "endpoint node is a binding prop" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        resource :posts, "/posts" do
          show do
            render "/presentation/endpoints/anchor/contextual/binding_prop"
          end
        end

        presenter "/presentation/endpoints/anchor/contextual/binding_prop" do
          def perform
            find(:post).bind(id: 5, title: "foo")
          end
        end
      }
    end

    it "builds the action using binding as context" do
      expect(call("/posts/1")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-id="5">
            <a data-b="title" data-e="posts_show" href="/posts/5">foo</a>
          </div>
        HTML
      )
    end
  end
end
