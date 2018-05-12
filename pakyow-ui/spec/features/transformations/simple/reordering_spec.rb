RSpec.describe "reordering a populated view" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.ordered
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

        update do
          verify do
            required :id
            required :post do
              required :title
            end
          end

          data.posts.by_id(params[:id]).update(params[:post])
        end

        collection do
          post "/reorder-all" do
            verify do
              required :post do
                required :title
              end
            end

            data.posts.update(params[:post])
          end
        end
      end

      source :posts do
        primary_id
        attribute :title

        def ordered
          order { title.asc }
        end
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms for a single reorder" do
    call("/posts", method: :post, params: { post: { title: "foo" } })
    call("/posts", method: :post, params: { post: { title: "bar" } })
    call("/posts", method: :post, params: { post: { title: "baz" } })
    call("/posts", method: :post, params: { post: { title: "qux" } })

    transformations = save_ui_case("reordering_one", path: "/posts") do
      expect(call("/posts/3", method: :patch, params: { post: { title: "aaa" } })[0]).to eq(200)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[{"id":3,"title":"aaa"},{"id":2,"title":"bar"},{"id":1,"title":"foo"},{"id":4,"title":"qux"}]],[],[]]]]]'
    )
  end

  it "transforms for a reorder of the entire set" do
    call("/posts", method: :post, params: { post: { title: "qux" } })
    call("/posts", method: :post, params: { post: { title: "foo" } })
    call("/posts", method: :post, params: { post: { title: "bar" } })
    call("/posts", method: :post, params: { post: { title: "baz" } })

    transformations = save_ui_case("reordering_all", path: "/posts") do
      expect(call("/posts/reorder-all", method: :post, params: { post: { title: "aaa" } })[0]).to eq(200)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[{"id":1,"title":"aaa"},{"id":2,"title":"aaa"},{"id":3,"title":"aaa"},{"id":4,"title":"aaa"}]],[],[]]]]]'
    )
  end
end
