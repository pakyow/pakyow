RSpec.describe "presenting data in a channeled binding" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose "posts:published", data.posts.published
          expose "posts:unpublished", data.posts.unpublished
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

      source :posts, timestamps: false do
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
        render do
          find("post:published").present(posts(:published))
          find("post:unpublished").present(posts(:unpublished))
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo", published: true } })
    call("/posts", method: :post, params: { post: { title: "bar", published: false } })

    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz", published: true } })
    end
  end
end
