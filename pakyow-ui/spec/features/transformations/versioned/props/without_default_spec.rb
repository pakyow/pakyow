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
          render do
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
          render :post, :title do
            use(:red)
          end
        end
      end
    end

    # FIXME: this is a bug that can only be solved by transforming templates on the client
    #
    xit "transforms" do |x|
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
          render :post, :title do
            use(:red).attrs[:style][:background] = "blue"
          end
        end
      end
    end

    # FIXME: this is a bug that can only be solved by transforming templates on the client
    #
    xit "transforms" do |x|
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
          render :post do
            present(posts)
          end

          render :post, :title do
            use(:red)
          end
        end
      end
    end

    # FIXME: this is a bug that can only be solved by transforming templates on the client
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
          render do
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
          render do
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
