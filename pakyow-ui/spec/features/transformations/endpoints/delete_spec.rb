RSpec.describe "presenting a view that defines an endpoint for delete" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new {
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
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
        find(:post).present(posts)
      end

      source :posts do
        primary_id

        attribute :title
      end
    }
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["wrapEndpointForRemoval",[{"name":"posts_delete","path":"/posts/1"}],[],[]],["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
    )
  end
end
