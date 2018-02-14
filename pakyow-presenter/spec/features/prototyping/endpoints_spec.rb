RSpec.describe "presenting prototypes that define endpoints" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resources :posts, "/posts" do
        list do
          render "/prototyping/endpoints"
        end
      end
    }
  end

  let :mode do
    :prototype
  end

  it "does not set the href" do
    expect(call("/prototyping/endpoints")[2].body.read).to eq_sans_whitespace(
      <<~HTML
        <a href="#"></a>
      HTML
    )
  end

  context "endpoint is current" do
    it "sets an active class" do
      expect(call("/prototyping/endpoints/current")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <a href="/prototyping/endpoints/current" class="active"></a>
        HTML
      )
    end
  end

  context "endpoint within a binding is current" do
    it "sets an active class" do
      expect(call("/prototyping/endpoints/current_within_binding")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <a href="/prototyping/endpoints/current" class="active"></a>
        HTML
      )
    end
  end

  context "endpoint that is a binding prop is current" do
    it "sets an active class" do
      expect(call("/prototyping/endpoints/current_binding_prop")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <a href="/prototyping/endpoints/current" data-b="title" class="active"></a>
        HTML
      )
    end
  end
end
