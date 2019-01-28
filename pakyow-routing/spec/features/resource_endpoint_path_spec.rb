RSpec.describe "resource endpoint path" do
  include_context "app"

  let :app_init do
    Proc.new {
      resource :posts, "/posts" do
        show do
          send connection.env["pakyow.endpoint.path"]
        end

        member do
          get :foo, "/foo" do
            send connection.env["pakyow.endpoint.path"]
          end
        end

        resource :comments, "/comments" do
          list do
            send connection.env["pakyow.endpoint.path"]
          end
        end
      end
    }
  end

  it "updates the endpoint path for show" do
    expect(call("/posts/1")[2].body.read).to eq("/posts/show")
  end

  it "updates the endpoint path for members" do
    expect(call("/posts/1/foo")[2].body.read).to eq("/posts/show/foo")
  end

  it "updates the endpoint path for nested resources" do
    expect(call("/posts/1/comments")[2].body.read).to eq("/posts/show/comments")
  end
end
