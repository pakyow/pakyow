RSpec.describe "clearing data in a populated view" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
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

        remove do
          data.posts.by_id(params[:id]).delete
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do
    call("/posts", method: :post, params: { post: { title: "foo" } })
    transformations = save_ui_case("clearing", path: "/posts") do
      call("/posts/1", method: :delete)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[]],[],[]]]]]'
    )
  end
end

RSpec.describe "clearing data in a populated view that contains an empty version" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/empty/posts"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end

        remove do
          data.posts.by_id(params[:id]).delete
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      presenter "/empty/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do
    call("/posts", method: :post, params: { post: { title: "foo" } })
    transformations = save_ui_case("data_to_empty", path: "/posts") do
      call("/posts/1", method: :delete)
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[]],[],[]]]]]'
    )
  end
end

