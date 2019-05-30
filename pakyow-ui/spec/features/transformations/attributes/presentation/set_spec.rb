RSpec.describe "modifying set attributes during presentation" do
  include_context "app"
  include_context "websocket intercept"

  context "setting" do
    let :app_init do
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
                post_view.attrs[:class] = [:foo, :bar]

                # if we don't set this, the view won't quite match
                post_view.attrs[:style] = {}
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

  context "adding a value with <<" do
    let :app_init do
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
                post_view.attrs[:class] << :foo

                # if we don't set this, the view won't quite match
                post_view.attrs[:style] = {}
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

  context "adding a value with add" do
    let :app_init do
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
                post_view.attrs[:class].add(:foo)

                # if we don't set this, the view won't quite match
                post_view.attrs[:style] = {}
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
    let :app_init do
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
                post_view.attrs[:class].delete(:one)

                # if we don't set this, the view won't quite match
                post_view.attrs[:style] = {}
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
    let :app_init do
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
                post_view.attrs[:class].clear

                # if we don't set this, the view won't quite match
                post_view.attrs[:style] = {}
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
