RSpec.describe "using specific versions inline" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/versioned/posts"
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
              required :published
            end
          end

          data.posts.by_id(params[:id]).update(params[:post])
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean, default: false
      end

      presenter "/versioned/posts" do
        if posts.count > 0
          post_view = find(:post)
          post_view.use(posts.one.published ? :published : :unpublished)
          post_view.present(posts.one)
        end
      end
    end
  end

  context "object is created in a way that sets version" do
    it "transforms" do
      transformations = save_ui_case("versioned_create_inline", path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["use",["unpublished"],[],[]],["present",[{"id":1,"title":"foo","published":null}],[],[]]]]]'
      )
    end
  end

  context "object is updated in a way that changes its version" do
    it "transforms" do
      call("/posts", method: :post, params: { post: { title: "foo" } })

      transformations = save_ui_case("versioned_value_change_inline", path: "/posts") do
        expect(call("/posts/1", method: :patch, params: { post: { published: true } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["use",["published"],[],[]],["present",[{"id":1,"title":"foo","published":true}],[],[]]]]]'
      )
    end
  end
end

RSpec.describe "using specific versions during presentation" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/versioned/posts"
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
              required :published
            end
          end

          data.posts.by_id(params[:id]).update(params[:post])
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean, default: false
      end

      presenter "/versioned/posts" do
        find(:post).present(posts) do |post_view, post|
          post_view.use(post.published ? :published : :unpublished)
        end
      end
    end
  end

  context "object is created in a way that sets version" do
    it "transforms" do
      transformations = save_ui_case("versioned_create", path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["unpublished"],[],[]]]],[]]]]]'
      )
    end
  end

  context "object is updated in a way that changes its version" do
    it "transforms" do
      call("/posts", method: :post, params: { post: { title: "foo" } })

      transformations = save_ui_case("versioned_value_change", path: "/posts") do
        expect(call("/posts/1", method: :patch, params: { post: { published: true } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["published"],[],[]]]],[]]]]]'
      )
    end
  end
end

RSpec.describe "using specific versions during presentation with a change occuring after" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/versioned/posts"
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
              required :published
            end
          end

          data.posts.by_id(params[:id]).update(params[:post])
        end
      end

      source :posts do
        primary_id
        attribute :title
        attribute :published, :boolean, default: false
      end

      presenter "/versioned/posts" do
        find(:post).present(posts) do |post_view, post|
          post_view.use(post.published ? :published : :unpublished)
          post_view.attrs[:style] = { color: "red" }
        end
      end
    end
  end

  context "object is created in a way that sets version" do
    it "transforms" do
      transformations = save_ui_case("versioned_create_before_attr_set", path: "/posts") do
        call("/posts", method: :post, params: { post: { title: "foo" } })
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["unpublished"],[],[]],["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
      )
    end
  end

  context "object is updated in a way that changes its version" do
    it "transforms" do
      call("/posts", method: :post, params: { post: { title: "foo" } })

      transformations = save_ui_case("versioned_value_change_before_attr_set", path: "/posts") do
        expect(call("/posts/1", method: :patch, params: { post: { published: true } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1,"title":"foo"}]],[[["use",["published"],[],[]],["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
      )
    end
  end
end
