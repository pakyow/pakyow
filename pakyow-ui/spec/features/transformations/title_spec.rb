RSpec.describe "changing the view title" do
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
        if posts.to_a.any?
          self.title = posts.one.title
        end
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["title=",["foo"],[],[]]]'
    )
  end
end