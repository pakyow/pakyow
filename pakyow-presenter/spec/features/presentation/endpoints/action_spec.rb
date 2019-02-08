RSpec.describe "presenting a view that defines an endpoints with an action" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        list do
          render "/presentation/endpoints/action"
        end
      end
    end
  end

  it "sets the href on the action node" do
    expect(call("/presentation/endpoints/action")[2].read).to include_sans_whitespace(
      <<~HTML
        <div data-e="posts_list">
          <a href="/posts" data-e-a=""></a>
        </div>
      HTML
    )
  end

  context "endpoint is current" do
    it "adds a current class to the endpoint node" do
      expect(call("/posts")[2].read).to include_sans_whitespace(
        <<~HTML
          <div data-e="posts_list" class="current">
            <a href="/posts" data-e-a=""></a>
          </div>
        HTML
      )
    end
  end
end
