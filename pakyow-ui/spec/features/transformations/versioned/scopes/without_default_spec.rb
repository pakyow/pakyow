require_relative "../shared"

RSpec.describe "versioned scopes with no default" do
  include_context "versioned"

  context "presentation occurs without use" do
    let :view_path do
      "/versioned/scopes"
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
      "/versioned/scopes"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).use(:unpublished)
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["use",["unpublished"],[],[]]]]]'
      )
    end
  end

  context "used and then further modified" do
    let :view_path do
      "/versioned/scopes"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).use(:unpublished).attrs[:style][:background] = "blue"
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["use",["unpublished"],[],[["attrs",[],[],[["[]",["style"],[],[["[]=",["background","blue"],[],[]]]]]]]]]]]'
      )
    end
  end

  context "used and then presented" do
    let :view_path do
      "/versioned/scopes"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).use(:unpublished).present(posts)
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["use",["unpublished"],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]]]'
      )
    end
  end

  context "used during presentation with no further action" do
    let :view_path do
      "/versioned/scopes"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).present(posts) do |post_view, post|
            post_view.use(post.published ? :published : :unpublished)
          end
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["unpublished"],[],[]]]],[]]]]]'
      )
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "foo" } })

        transformations = save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { published: true } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["published"],[],[]]]],[]]]]]'
        )
      end
    end
  end

  context "used during presentation and then further modified" do
    let :view_path do
      "/versioned/scopes"
    end

    let :presenter do
      local_view_path = view_path

      Proc.new do
        presenter local_view_path do
          find(:post).present(posts) do |post_view, post|
            post_view.use(post.published ? :published : :unpublished)
            post_view.attrs[:style] = { color: "red" }
          end
        end
      end
    end

    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["unpublished"],[],[]],["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
      )
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "foo" } })

        transformations = save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { published: true } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["published"],[],[]],["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
        )
      end
    end
  end
end
