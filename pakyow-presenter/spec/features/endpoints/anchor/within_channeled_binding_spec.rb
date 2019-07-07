RSpec.describe "presenting a view that defines an anchor endpoint within a channeled binding" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        list do
        end
      end

      presenter "/presentation/endpoints/anchor/within_channeled_binding" do
        render "post:foo" do
          present(title: "foo")
        end
      end
    end
  end

  it "sets the href" do
    expect(call("/presentation/endpoints/anchor/within_channeled_binding")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post:foo">
          <h1 data-b="title">foo</h1>

          <a href="/posts" data-e="posts_list">Back</a>
        </div>
      HTML
    )
  end

  context "endpoint is current" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          list do
            expose "post:foo", { title: "foo" }
            render "/presentation/endpoints/anchor/within_channeled_binding"
          end
        end
      end
    end

    it "receives a current class" do
      expect(call("/posts")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post:foo">
            <h1 data-b="title">foo</h1>

            <a href="/posts" data-e="posts_list" class="ui-current">Back</a>
          </div>
        HTML
      )
    end
  end
end
