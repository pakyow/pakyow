RSpec.describe "presenting an object with a value overridden in a binder" do
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
      end

      source :posts do
        primary_id
        attribute :title
      end

      binder :post do
        def title
          @object[:title].reverse
        end
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["present",[[{"id":1,"title":"oof"}]],[],[]]]]]'
    )
  end
end

RSpec.describe "presenting an object with a value defined only in a binder" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/binder/posts"
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

      binder :post do
        def reversed_title
          @object[:title].reverse
        end
      end

      presenter "/binder/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do |x|
    transformations = save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",[["post"]],[],[["present",[[{"id":1,"title":"foo","reversed_title":"oof"}]],[],[]]]]]'
    )
  end
end
