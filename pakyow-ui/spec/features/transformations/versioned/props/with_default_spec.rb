require_relative "../shared"

RSpec.shared_context "default versions" do
  include_context "versioned"

  context "presentation occurs without use" do
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
        '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
      )
    end
  end

  context "implicitly using the default" do
    context "used and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post, :title).attrs[:style][:background] = "blue"
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post","title"]],[],[["attributes",[],[],[["get",["style"],[],[["set",["background","blue"],[],[]]]]]]]]]'
        )
      end
    end

    context "used during presentation with no further action" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              if post.title.include?("red")
                post_view.find(:title).use(:red)
              end
            end
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
          call("/posts", method: :post, params: { post: { title: "red foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
        )
      end

      context "changed later" do
        it "transforms" do |x|
          call("/posts", method: :post, params: { post: { title: "foo" } })

          transformations = save_ui_case(x, path: "/posts") do
            expect(call("/posts/1", method: :patch, params: { post: { title: "red foo" } })[0]).to eq(200)
          end

          expect(transformations[0][:calls].to_json).to eq(
            '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
          )
        end
      end
    end

    context "used during presentation and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              if post.title.include?("red")
                post_view.find(:title).use(:red)
              end

              post_view.find(:title).attrs[:style] = { background: "gray" }
            end
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "red foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attributes",[],[],[["set",["style",{"background":"gray"}],[],[]]]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
        )
      end

      context "changed later" do
        it "transforms" do |x|
          call("/posts", method: :post, params: { post: { title: "foo" } })

          transformations = save_ui_case(x, path: "/posts") do
            expect(call("/posts/1", method: :patch, params: { post: { title: "red" } })[0]).to eq(200)
          end

          expect(transformations[0][:calls].to_json).to eq(
            '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attributes",[],[],[["set",["style",{"background":"gray"}],[],[]]]]]],["bind",[{"id":1,"title":"red"}],[],[]]]],[]]]]]'
          )
        end
      end
    end
  end

  context "explicitly using the default" do
    context "used with no further action" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post, :title).use(:default)
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post","title"]],[],[["use",["default"],[],[]]]]]'
        )
      end
    end

    context "used and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post, :title).use(:default).attrs[:style][:background] = "blue"
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post","title"]],[],[["use",["default"],[],[["attributes",[],[],[["get",["style"],[],[["set",["background","blue"],[],[]]]]]]]]]]]'
        )
      end
    end

    context "used during presentation with no further action" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              if post.title.include?("red")
                post_view.find(:title).use(:red)
              else
                post_view.find(:title).use(:default)
              end
            end
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "red foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
        )
      end

      context "changed later" do
        it "transforms" do |x|
          call("/posts", method: :post, params: { post: { title: "foo" } })

          transformations = save_ui_case(x, path: "/posts") do
            expect(call("/posts/1", method: :patch, params: { post: { title: "red foo" } })[0]).to eq(200)
          end

          expect(transformations[0][:calls].to_json).to eq(
            '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
          )
        end
      end
    end

    context "used during presentation and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              if post.title.include?("red")
                post_view.find(:title).use(:red)
              else
                post_view.find(:title).use(:red)
              end

              post_view.find(:title).attrs[:style] = { background: "gray" }
            end
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "red foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attributes",[],[],[["set",["style",{"background":"gray"}],[],[]]]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
        )
      end

      context "changed later" do
        it "transforms" do |x|
          call("/posts", method: :post, params: { post: { title: "foo" } })

          transformations = save_ui_case(x, path: "/posts") do
            expect(call("/posts/1", method: :patch, params: { post: { title: "red foo" } })[0]).to eq(200)
          end

          expect(transformations[0][:calls].to_json).to eq(
            '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"red foo"}]],[[["find",[["title"]],[],[["use",["red"],[],[]]]],["find",[["title"]],[],[["attributes",[],[],[["set",["style",{"background":"gray"}],[],[]]]]]],["bind",[{"id":1,"title":"red foo"}],[],[]]]],[]]]]]'
          )
        end
      end
    end
  end
end

RSpec.describe "versioned props with an explicit default" do
  include_context "default versions"

  let :view_path do
    "/versioned/props/defaults"
  end
end

RSpec.describe "versioned props with an implicit default" do
  include_context "default versions"

  let :view_path do
    "/versioned/props/defaults/implicit"
  end
end
