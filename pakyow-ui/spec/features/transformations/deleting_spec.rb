RSpec.describe "deleting an object in a populated view" do
  include_context "app"
  include_context "websocket intercept"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/simple/posts"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end

        delete do
          data.posts.by_id(params[:id]).delete
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
      end

      presenter "/simple/posts" do
        def perform
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo" } })
    call("/posts", method: :post, params: { post: { title: "bar" } })
    call("/posts", method: :post, params: { post: { title: "baz" } })
    call("/posts", method: :post, params: { post: { title: "qux" } })

    save_ui_case(x, path: "/posts") do
      call("/posts/3", method: :delete)
    end
  end
end
