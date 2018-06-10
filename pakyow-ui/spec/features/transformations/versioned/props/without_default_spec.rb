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
          def perform
            find(:post).present(posts)
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end
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
          def perform
            find(:post, :title).use(:red)
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end
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
          def perform
            find(:post, :title).use(:red).attrs[:style][:background] = "blue"
          end
        end
      end
    end

    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end
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
          def perform
            find(:post, :title).use(:red)
            find(:post).present(posts)
          end
        end
      end
    end

    # This is unsupported, and may always be. In order to support it on the client,
    # we'd need to apply transformations to templates as well as rendered views.
    # If this comes back to bite us in other ways, we'll revisit.
    #
    xit "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end
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
          def perform
            find(:post).present(posts) do |post_view, post|
              post_view.find(:title).use(post.title.include?("red") ? :red : :blue)
            end
          end
        end
      end
    end

    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "blue foo" } })

      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "red foo" } })
      end
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "foo" } })
        call("/posts", method: :post, params: { post: { title: "blue foo" } })
        call("/posts", method: :post, params: { post: { title: "red foo" } })

        save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "red foo2" } })[0]).to eq(200)
        end
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
          def perform
            find(:post).present(posts) do |post_view, post|
              post_view.find(:title).use(post.title.include?("red") ? :red : :blue)
              post_view.find(:title).attrs[:style] = { background: "gray" }
            end
          end
        end
      end
    end

    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "red foo" } })

      save_ui_case(x, path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "blue foo" } })
      end
    end

    context "changed later" do
      it "transforms" do |x|
        call("/posts", method: :post, params: { post: { title: "blue foo" } })

        save_ui_case(x, path: "/posts") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "red foo" } })[0]).to eq(200)
        end
      end
    end
  end
end
