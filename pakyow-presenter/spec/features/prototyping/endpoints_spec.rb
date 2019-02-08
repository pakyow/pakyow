RSpec.describe "presenting prototypes that define endpoints" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        list do
          render "/prototyping/endpoints"
        end
      end
    end
  end

  let :mode do
    :prototype
  end

  it "does not set the href" do
    expect(call("/prototyping/endpoints")[2].read).to eq_sans_whitespace(
      <<~HTML
        <a href="#" data-e="posts_list"></a>
      HTML
    )
  end

  context "endpoint is current" do
    it "sets a current class" do
      expect(call("/prototyping/endpoints/current")[2].read).to eq_sans_whitespace(
        <<~HTML
          <a href="/prototyping/endpoints/current" data-e="posts_list" class="current"></a>
        HTML
      )
    end
  end

  context "endpoint within a binding is active" do
    it "sets an active class" do
      expect(call("/prototyping/endpoints/current_within_binding")[2].read).to include_sans_whitespace(
        <<~HTML
          <a href="/prototyping/endpoints/current" data-e="posts_list" class="active"></a>
        HTML
      )
    end
  end

  context "endpoint that is a binding prop is active" do
    it "sets an active class" do
      expect(call("/prototyping/endpoints/current_binding_prop")[2].read).to include_sans_whitespace(
        <<~HTML
          <a data-b="title" href="/prototyping/endpoints/current" data-e="posts_list" class="active"></a>
        HTML
      )
    end
  end
end
