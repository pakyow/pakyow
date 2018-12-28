RSpec.describe "presenting an object with binding parts defined in a binder" do
  include_context "app"
  include_context "websocket intercept"

  let :app_init do
    Proc.new do
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

      binder :post do
        def title
          part :content do
            object[:title].to_s.reverse
          end

          part :style do
            { color: "red" }
          end

          part :class do
            [:fooclass]
          end

          part :title do
            object[:title]
          end

          part :selected do
            true
          end
        end
      end

      presenter "/simple/posts" do
        def perform
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end
  end
end
