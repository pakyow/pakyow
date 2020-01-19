RSpec.describe "presenting data in a wrapped binding prop" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.including(:comments)
          render "/wrapped-binding-prop/posts"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end

        resource :comments, "/comments" do
          disable_protection :csrf

          create do
            verify do
              required :comment do
                required :body
              end
            end

            params[:comment][:post_id] = params[:post_id]
            data.comments.create(params[:comment]); halt
          end
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
        has_many :comments
      end

      source :comments, timestamps: false do
        primary_id
        attribute :body
      end
    end
  end

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo" } })

    save_ui_case(x, path: "/posts") do
      call("/posts/1/comments", method: :post, params: { comment: { body: "foo comment" } })
    end
  end
end
