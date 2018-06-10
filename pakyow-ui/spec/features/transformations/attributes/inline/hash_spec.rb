RSpec.describe "modifying hash attributes" do
  include_context "testable app"
  include_context "websocket intercept"

  context "setting" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:style] = { color: "red" }
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
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:style][:color] = "red"
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
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:style].delete(:background)
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
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:style].clear
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
