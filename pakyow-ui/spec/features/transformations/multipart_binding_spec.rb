RSpec.describe "presenting data in a multipart binding" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/multipart/posts"
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

      source :posts do
        primary_id
        attribute :title
      end

      presenter "/channeled/posts" do
        def perform
          find(:post).present(posts)
        end
      end
    end
  end

  context "no data or empty" do
    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end
    end
  end

  context "existing data" do
    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "foo" } })

      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "bar" } })
      end
    end
  end
end
