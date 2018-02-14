RSpec.describe "presenting a view that defines an endpoint for removal" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resources :posts, "/posts" do
        show do
          render "/presentation/endpoints/remove"
        end

        remove do; end
      end
    }
  end

  it "wraps the node in a submittable form" do
    expect(call("/posts/1")[2].body.read).to eq_sans_whitespace(
      <<~HTML
        <form action="/posts/1" method="post" data-ui="confirm">
          <input type="hidden" name="_method" value="delete">

          <button>delete</button>
        </form>
      HTML
    )
  end
end
