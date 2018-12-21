RSpec.describe "presenting an object in a component" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
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

      source :posts, timestamps: false do
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

RSpec.describe "presenting the same data in a component and outside of it" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts, for: :all
          render "/components/multi-posts"
        end

        create do
          verify do
            required :post do
              required :title
              required :body
              optional :type
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
        attribute :body
        attribute :type

        def recent
          where(type: "recent")
        end
      end

      component :posts do
        def perform
          expose :posts, data.posts.recent
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo", body: "foo body" } })
    call("/posts", method: :post, params: { post: { title: "bar", body: "bar body", type: "recent" } })

    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", body: "baz body", type: "recent" } })
    end
  end
end
