require_relative "../shared"

RSpec.describe "versioned props with no default" do
  include_context "versioned"

  context "presentation occurs without use" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).present(posts)
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]'
      )
    end
  end

  context "used with no further action" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post, :title).use(:red)
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post","title"]],[],[["use",["red"],[],[]]]]]'
      )
    end
  end

  context "used and then further modified" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post, :title).use(:red).attrs[:style][:background] = "blue"
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post","title"]],[],[["use",["red"],[],[["attrs",[],[],[["[]",["style"],[],[["[]=",["background","blue"],[],[]]]]]]]]]]]'
      )
    end
  end

  context "used and then presented" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post, :title).use(:red)
          find(:post).present(posts)
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post","title"]],[],[["use",["red"],[],[]]]],["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]'
      )
    end
  end

  context "used during presentation with no further action" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).present(posts) do |post_view, post|
            post_view.find(:title).use(post.title.include?("red") ? :red : :blue)
          end
        end
      end
    end

    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "blue foo" } })

      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "red foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"blue foo"},{"id":2,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["blue"],[],[]]]]],[["find",[["title"]],[],[["use",["red"],[],[]]]]]],[]]]]]'
      )
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "foo" } })
        call("/posts", method: :post, params: { post: { title: "blue foo" } })
        call("/posts", method: :post, params: { post: { title: "red foo" } })

        transformations = save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "red foo2" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["present",[[{"id":1,"title":"red foo2"},{"id":2,"title":"blue foo"},{"id":3,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]]],[["find",[["title"]],[],[["use",["blue"],[],[]]]]],[["find",[["title"]],[],[["use",["red"],[],[]]]]]],[]]]]]'
        )
      end
    end
  end

  context "used during presentation and then further modified" do
    let :view_path do
      "/versioned/props"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).present(posts) do |post_view, post|
            post_view.find(:title).use(post.title.include?("red") ? :red : :blue)
            post_view.find(:title).attrs[:style] = { background: "gray" }
          end
        end
      end
    end

    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "red foo" } })

      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "blue foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"red foo"},{"id":2,"title":"blue foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attrs",[],[],[["[]=",["style",{"background":"gray"}],[],[]]]]]]],[["find",[["title"]],[],[["use",["blue"],[],[]]]],["find",[["title"]],[],[["attrs",[],[],[["[]=",["style",{"background":"gray"}],[],[]]]]]]]],[]]]]]'
      )
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "blue foo" } })

        transformations = save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "red foo" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["present",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attrs",[],[],[["[]=",["style",{"background":"gray"}],[],[]]]]]]]],[]]]]]'
        )
      end
    end
  end
end
