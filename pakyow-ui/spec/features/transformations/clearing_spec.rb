RSpec.describe "clearing data in a populated view" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
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

RSpec.describe "clearing data in a populated view that contains an empty version" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/empty/posts"
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

      presenter "/empty/posts" do
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

