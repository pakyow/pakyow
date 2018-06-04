RSpec.describe "presenting a view that defines an anchor endpoint within a binding" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new {
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/endpoints/anchor/within_binding"
        end

        show do
          expose :posts, data.posts.by_id(params[:id].to_i)
          render "/endpoints/anchor/within_binding"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post])
        end

        update do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.update(params[:post])
        end

        member do
          get :related, "/related" do
            expose :posts, data.posts
            render "/endpoints/anchor/within_binding"
          end
        end
      end

      presenter "/endpoints/anchor/within_binding" do
        find(:post).present(posts)
      end

      source :posts do
        primary_id

        attribute :title
      end
    }
  end

  context "binding is bound to" do
    it "transforms" do |x|
      transformations = save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["bind",[{"id":1,"title":"foo"}],[],[]]]],[]]]]]'
      )
    end

    context "endpoint is current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        transformations = save_ui_case(x, path: "/posts/1") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "bar" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"bar"}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["bind",[{"id":1,"title":"bar"}],[],[]]]],[]]]]]'
        )
      end
    end

    context "endpoint matches the first part of current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        transformations = save_ui_case(x, path: "/posts/1/related") do
          expect(call("/posts", method: :post, params: { post: { title: "bar" } })[0]).to eq(200)
        end

        expect(transformations[0][:calls].to_json).to eq(
          '[["find",[["post"]],[],[["transform",[[{"id":1,"title":"foo"},{"id":2,"title":"bar"}]],[[["setupEndpoint",[{"name":"posts_show","path":"/posts/1"}],[],[]],["bind",[{"id":1,"title":"foo"}],[],[]]],[["setupEndpoint",[{"name":"posts_show","path":"/posts/2"}],[],[]],["bind",[{"id":2,"title":"bar"}],[],[]]]],[]]]]]'
        )
      end
    end
  end
end
