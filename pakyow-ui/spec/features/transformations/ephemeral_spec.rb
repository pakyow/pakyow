RSpec.describe "mutating a presented ephemeral" do
  include_context "app"
  include_context "websocket intercept"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.ephemeral(:posts).set([])
          render "/simple/posts"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.ephemeral(:posts).set([params[:post]])
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
    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end
  end
end
