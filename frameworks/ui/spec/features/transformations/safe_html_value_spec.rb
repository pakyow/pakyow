RSpec.describe "presenting an object with a safe html value" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/simple/posts"
        end

        create do
          data.posts.create(title: "<strong>hi</strong>"); halt
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
      end

      binder :post do
        def title
          html_safe(@object[:title])
        end
      end

      presenter "/simple/posts" do
        render do
          find(:post).present(posts)
        end
      end
    end
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post)
    end
  end
end
