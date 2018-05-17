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
        '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]'
      )
    end
  end

  context "implicitly using the default" do
    context "used and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).attrs[:style][:background] = "blue"
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["attrs",[],[],[["[]",["style"],[],[["[]=",["background","blue"],[],[]]]]]]]]]'
        )
      end
    end

    context "used and then presented" do
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

    context "used during presentation with no further action" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              unless post.published
                post_view.use(:unpublished)
              end
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
            '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[]],[]]]]]'
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
              unless post.published
                post_view.use(:unpublished)
              end

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
            '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
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
            find(:post).use(:default)
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["use",["default"],[],[]]]]]'
        )
      end
    end

    context "used and then further modified" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).use(:default).attrs[:style][:background] = "blue"
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["use",["default"],[],[["attrs",[],[],[["[]",["style"],[],[["[]=",["background","blue"],[],[]]]]]]]]]]]'
        )
      end
    end

    context "used and then presented" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).use(:default).present(posts)
          end
        end
      end

      it "transforms" do |x|
        transformations = save_ui_case(x, path: "/posts") do
          call("/posts", method: :post, params: { post: { title: "foo" } })
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["use",["default"],[],[["present",[[{"id":1,"title":"foo"}]],[],[]]]]]]]'
        )
      end
    end

    context "used during presentation with no further action" do
      let :presenter do
        local_view_path = view_path

        Proc.new do
          presenter local_view_path do
            find(:post).present(posts) do |post_view, post|
              if post.published
                post_view.use(:default)
              else
                post_view.use(:unpublished)
              end
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
            '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["default"],[],[]]]],[]]]]]'
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
              if post.published
                post_view.use(:default)
              else
                post_view.use(:unpublished)
              end

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
            '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["default"],[],[]],["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
          )
        end
      end
    end
  end
end

RSpec.describe "versioned scopes with an explicit default" do
  include_context "default versions"

  let :view_path do
    "/versioned/scopes/defaults"
  end
end

RSpec.describe "versioned scopes with an implicit default" do
  include_context "default versions"

  let :view_path do
    "/versioned/scopes/defaults/implicit"
  end
end
