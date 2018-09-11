RSpec.describe "presenting a view that defines an endpoint for delete" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new {
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/endpoints/delete"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post])
        end

        delete do; end
      end

      presenter "/endpoints/delete" do
        def perform
          find(:post).present(posts)
        end
      end

      source :posts do
        primary_id

        attribute :title
      end
    }
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/posts") do
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
    end
  end
end
