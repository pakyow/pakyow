RSpec.describe "presenting data in a channeled binding" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :published, data.posts.published
          expose :unpublished, data.posts.unpublished
          render "/channeled/posts"
        end

        create do
          verify do
            required :post do
              required :title
              required :published, :boolean
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean

        def published
          where(published: true)
        end

        def unpublished
          where(published: false)
        end
      end

      presenter "/channeled/posts" do
        find("post:published").present(published)
        find("post:unpublished").present(unpublished)
      end
    end
  end

  it "transforms" do
    call("/posts", method: :post, params: { post: { title: "foo", published: true } })
    call("/posts", method: :post, params: { post: { title: "bar", published: false } })

    transformations = save_ui_case("presenting_channeled", path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", published: true } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post:published"],[],[["present",[[{"id":1,"title":"foo"},{"id":3,"title":"baz"}]],[],[]]]],["find",["post:unpublished"],[],[["present",[[{"id":2,"title":"bar"}]],[],[]]]]]'
    )
  end
end

RSpec.describe "presenting data across channeled bindings" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/channeled/posts"
        end

        create do
          verify do
            required :post do
              required :title
              required :published, :boolean
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean
      end

      presenter "/channeled/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do
    call("/posts", method: :post, params: { post: { title: "foo", published: true } })
    call("/posts", method: :post, params: { post: { title: "bar", published: false } })

    transformations = save_ui_case("presenting_channeled_across", path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", published: true } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[{"id":1,"title":"foo"},{"id":2,"title":"bar"},{"id":3,"title":"baz"}]],[],[]]]]]'
    )
  end
end
