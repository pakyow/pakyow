RSpec.describe "presenting a view that defines an anchor endpoint within a binding" do
  include_context "app"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        list do
          render "/presentation/endpoints/anchor/within_binding"
        end
      end

      presenter "/presentation/endpoints/anchor/within_binding" do
        render :post do
          present(title: "foo")
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

            <a href="/posts" data-e="posts_list" class="ui-current">Back</a>
          </div>
        HTML
      )
    end
  end
end
