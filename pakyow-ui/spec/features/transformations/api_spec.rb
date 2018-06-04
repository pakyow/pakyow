RSpec.describe "api" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    local_presenter = presenter
    local_view_path = view_path

    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
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

      source :posts do
        primary_id
        attribute :title
      end

      presenter local_view_path do
        instance_exec(&local_presenter)
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["setTitle",["foo"],[],[]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["attributes",[],[],[["get",["style"],[],[["set",["background","purple"],[],[]]]]]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["append",["foo"],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["prepend",["foo"],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["after",["foo"],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["before",["foo"],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["replace",["foo"],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["remove",[],[],[]]]]]'
      )
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
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["bind",[{"id":1,"title":"foo"}],[],[]],["clear",[],[],[]]]]]'
      )
    end
  end
end
