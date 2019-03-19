RSpec.describe "presenting a view that defines an anchor endpoint within a binding" do
  include_context "app"

  it "does not set the href automatically" do
    expect(call("/presentation/endpoints/anchor/within_binding")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post">
          <h1 data-b="title">title</h1>

          <a href="#" data-e="posts_list">Back</a>
        </div>
      HTML
    )
  end

  context "binding is bound to" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          list do
            render "/presentation/endpoints/anchor/within_binding"
          end
        end

        presenter "/presentation/endpoints/anchor/within_binding" do
          def perform
            find(:post).present(title: "foo")
          end
        end
      end
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/within_binding")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            <a href="/posts" data-e="posts_list">Back</a>
          </div>
        HTML
      )
    end

    context "endpoint is current" do
      it "receives a current class" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title">foo</h1>

              <a href="/posts" data-e="posts_list" class="current">Back</a>
            </div>
          HTML
        )
      end
    end
  end
end
