RSpec.describe "modifying boolean attributes" do
  include_context "testable app"
  include_context "websocket intercept"

  context "setting to true" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

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

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:selected] = true

              # if we don't set this, the view won't quite match
              find(:post).attrs[:style] = {}
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

  context "setting to false" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

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

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).attrs[:selected] = false

              # if we don't set this, the view won't quite match
              find(:post).attrs[:style] = {}
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
