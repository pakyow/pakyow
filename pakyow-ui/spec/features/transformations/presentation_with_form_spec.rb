RSpec.describe "presenting data alongside a form" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/form/posts"
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

      presenter "/form/posts" do
        form(:post).create(title: "")
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]'
    )
  end
end
