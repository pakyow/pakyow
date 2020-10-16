RSpec.describe "presenting data in a view that previously presented a nil value" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.one
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
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
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

RSpec.describe "presenting a nil value in a view that previously presented data" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.one
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
          data.posts.by_id(params[:id]).delete; halt
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
      end

      presenter "/simple/posts" do
        render do
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo" } })

    save_ui_case(x, path: "/posts") do
      call("/posts/1", method: :delete)
    end
  end
end
