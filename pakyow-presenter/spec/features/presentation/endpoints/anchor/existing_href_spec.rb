RSpec.describe "presenting a view that defines an anchor endpoint with an existing href" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        list do
          render "/presentation/endpoints/anchor/existing_href"
        end
      end
    end
  end

  context "defined endpoint is not found, but current endpoint matches the href" do
    it "receives a current class" do
      expect(call("/posts")[2].read).to include_sans_whitespace(
        <<~HTML
          <a href="/posts" data-e="posts_nonexistent" class="current"></a>
        HTML
      )
    end
  end
end
