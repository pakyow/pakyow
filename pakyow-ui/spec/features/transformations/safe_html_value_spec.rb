RSpec.describe "presenting an object with a safe html value" do
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
          data.posts.create(title: "<strong>hi</strong>"); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      binder :post do
        def title
          safe(@object[:title])
        end
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["present",[[{"id":1,"title":"<strong>hi</strong>"}]],[],[]]]]]'
    )
  end
end
