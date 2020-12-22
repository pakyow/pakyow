RSpec.describe "mutating a presented ephemeral" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.ephemeral(:posts).set(params[:posts].to_a)
          render "/simple/posts"
        end

        create do
          verify do
            required :posts do
              optional :id
              required :title
            end
          end

          data.ephemeral(:posts).set(params[:posts])
        end
      end

      presenter "/simple/posts" do
        render do
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/posts", result: -> { call("/posts", params: { posts: [{ id: 1, title: "foo" }] })[2] }) do
      call("/posts", method: :post, params: { posts: [{ id: 1, title: "foo" }] })
    end
  end
end
