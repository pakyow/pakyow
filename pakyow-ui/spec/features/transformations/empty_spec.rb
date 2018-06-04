RSpec.describe "presenting data into a previously empty view" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
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

      source :posts do
        primary_id
        attribute :title
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
    )
  end
end

RSpec.describe "presenting data into a previously empty view that contains an empty version" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/empty/posts"
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

      presenter "/empty/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
    )
  end
end
