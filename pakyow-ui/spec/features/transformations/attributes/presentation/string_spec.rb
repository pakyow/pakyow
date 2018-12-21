RSpec.describe "modifying string attributes during presentation" do
  include_context "testable app"
  include_context "websocket intercept"

  context "setting" do
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

        source :posts, timestamps: false do
          primary_id
        end

        presenter "/attributes/posts" do
          def perform
            if posts.count > 0
              find(:post).present(posts) do |post_view, post|
                post_view.attrs[:title] = "foo"

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
