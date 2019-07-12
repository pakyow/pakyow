RSpec.describe "including components defined on a delete endpoint" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        show do
          expose :post, { id: 1, title: "foo" }
          render "/presentation/endpoints/delete"
        end

        delete do; end
      end
    end
  end

  it "includes the packs" do
    expect(call("/posts/1")[2]).to include_sans_whitespace(
      <<~HTML
        <script src="/assets/packs/test.js"></script>
       <link rel="stylesheet" type="text/css" media="all" href="/assets/packs/test.css">
      HTML
    )
  end
end
