RSpec.describe "presenting an object in a component" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      component :posts do
        def perform
          expose :posts, data.posts
        end
      end
    end
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/components/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end
  end
end
