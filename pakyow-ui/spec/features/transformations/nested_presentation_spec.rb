RSpec.describe "presentating nested data" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.including(:comments)
          render "/nested/posts"
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

      resource :comments, "/comments" do
        disable_protection :csrf

        create do
          verify do
            required :comment do
              required :post_id
              required :title
            end
          end

          data.comments.create(params[:comment]); halt
        end
      end

      source :posts, timestamps: false do
        primary_id
        has_many :comments
        attribute :title
      end

      source :comments, timestamps: false do
        primary_id
        attribute :title
      end

      presenter "/nested/posts" do
        def perform
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo" } })

    save_ui_case(x, path: "/posts") do
      call("/comments", method: :post, params: { comment: { post_id: 1, title: "foo comment" } })
    end
  end
end
