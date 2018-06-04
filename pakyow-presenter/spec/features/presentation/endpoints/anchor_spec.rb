RSpec.describe "presenting a view that defines an anchor endpoint" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resources :posts, "/posts" do
        list do
          render "/presentation/endpoints/anchor"
        end

        show do
          render "/presentation/endpoints/anchor"
        end
      end
    }
  end

  it "sets the href" do
    expect(call("/presentation/endpoints/anchor")[2].body.read).to eq_sans_whitespace(
      <<~HTML
        <a href="/posts" data-e="posts_list"></a>
      HTML
    )
  end

  context "endpoint is current" do
    it "receives a current class" do
      expect(call("/posts")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <a href="/posts" data-e="posts_list" class="current"></a>
        HTML
      )
    end
  end

  context "endpoint matches the first part of current" do
    it "receives an active class" do
      expect(call("/posts/1")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <a href="/posts" data-e="posts_list" class="active"></a>
        HTML
      )
    end
  end

  context "endpoint does not exist" do
    it "does not set the href" do
      expect(call("/presentation/endpoints/anchor/nonexistent")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <a href="#" data-e="posts_nonexistent"></a>
        HTML
      )
    end
  end
end
