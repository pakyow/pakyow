RSpec.describe "api" do
  include_context "app"
  include_context "websocket intercept"

  let :app_init do
    $local_presenter = presenter
    local_view_path = view_path

    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render local_view_path
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

      presenter local_view_path do
        def perform
          instance_exec(&$local_presenter)
        end
      end
    end
  end

  let :view_path do
    "/simple/posts"
  end

  describe "title=" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          self.title = posts.one.title
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "transform" do
    let :presenter do
      Proc.new do
        find(:post).transform(posts) do |post_view, post|
          post_view.bind(post)
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "bind" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one)
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "with" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).with do |post_view|
            post_view.bind(posts.one)
            post_view.attrs[:style][:background] = "purple"
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "append" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).append("foo")
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "prepend" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).prepend("foo")
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "after" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).after("foo")
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "before" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).before("foo")
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "replace" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).replace("foo")
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "remove" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).remove
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end

  describe "clear" do
    let :presenter do
      Proc.new do
        if posts.to_a.any?
          find(:post).bind(posts.one).clear
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end
  end
end
