RSpec.describe "presenting data in a multipart binding" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
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

      source :posts, timestamps: false do
        primary_id
        attribute :title
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
