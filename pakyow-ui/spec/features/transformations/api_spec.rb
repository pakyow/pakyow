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
          expose :data, data.posts
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
        instance_exec(&$local_presenter)
      end
    end
  end

  let :view_path do
    "/simple/posts"
  end

  describe "title=" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            self.title = data.one.title
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

  describe "transform" do
    let :presenter do
      Proc.new do
        render do
          find(:post).transform(data) do |post_view, post|
            post_view.bind(post)
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

  describe "bind" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one)
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

  describe "with" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).with do |post_view|
              post_view.bind(data.one)
              post_view.attrs[:style][:background] = "purple"
            end
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
        render do
          if data.to_a.any?
            find(:post).bind(data.one).append("foo")
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

  describe "prepend" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).prepend("foo")
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

  describe "after" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).after("foo")
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

  describe "before" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).before("foo")
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

  describe "replace" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).replace("foo")
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

  describe "remove" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).remove
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

  describe "clear" do
    let :presenter do
      Proc.new do
        render do
          if data.to_a.any?
            find(:post).bind(data.one).clear
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
end
