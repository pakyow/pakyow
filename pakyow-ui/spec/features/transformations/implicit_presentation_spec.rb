RSpec.describe "implicit presentation" do
  include_context "app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

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
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
      end
    end
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/posts") do
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
    end
  end
end
