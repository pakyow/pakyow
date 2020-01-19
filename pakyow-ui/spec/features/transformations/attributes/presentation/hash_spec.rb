RSpec.describe "modifying hash attributes during presentation" do
  include_context "app"
  include_context "websocket intercept"

  context "setting" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts, timestamps: false do
          primary_id
        end

        presenter "/attributes/posts" do
          render do
            if posts.count > 0
              find(:post).present(posts) do |post_view, post|
                post_view.attrs[:style] = { color: "red" }
              end
            end
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post)
      end
    end
  end

  context "changing a value" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts, timestamps: false do
          primary_id
        end

        presenter "/attributes/posts" do
          render do
            if posts.count > 0
              find(:post).present(posts) do |post_view, post|
                post_view.attrs[:style][:color] = "red"
              end
            end
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post)
      end
    end
  end

  context "deleting a value" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts, timestamps: false do
          primary_id
        end

        presenter "/attributes/posts" do
          render do
            if posts.count > 0
              find(:post).present(posts) do |post_view, post|
                post_view.attrs[:style].delete(:background)
              end
            end
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post)
      end
    end
  end

  context "clearing" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts, timestamps: false do
          primary_id
        end

        presenter "/attributes/posts" do
          render do
            if posts.count > 0
              find(:post).present(posts) do |post_view, post|
                post_view.attrs[:style].clear
              end
            end
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post)
      end
    end
  end
end
