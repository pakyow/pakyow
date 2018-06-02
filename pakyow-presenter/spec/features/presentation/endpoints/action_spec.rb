RSpec.describe "presenting a view that defines an endpoints with an action" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resources :posts, "/posts" do
        list do
          render "/presentation/endpoints/action"
        end
      end
    }
  end

  it "sets the href on the action node" do
    expect(call("/presentation/endpoints/action")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <div data-e="posts_list">
          <a href="/posts"></a>
        </div>
      HTML
    )
  end

  context "endpoint is current" do
    it "adds an active class to the endpoint node" do
      expect(call("/posts")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <div data-e="posts_list" class="active">
            <a href="/posts"></a>
          </div>
        HTML
      )
    end
  end
end
