RSpec.describe "presenting a view that defines an anchor endpoint that is a binding scope" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    Proc.new {
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/endpoints/anchor/binding_scope"
        end

        show do
          expose :posts, data.posts.by_id(params[:id].to_i)
          render "/endpoints/anchor/binding_scope"
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
            render "/endpoints/anchor/binding_scope"
          end
        end
      end

      # presenter "/endpoints/anchor/binding_scope" do
      #   def perform
      #     find(:post).present(posts)
      #   end
      # end

      source :posts, timestamps: false do
        primary_id

        attribute :title
      end
    }
  end

  context "binding is bound to" do
    it "transforms" do |x|
      save_ui_case(x, path: "/posts") do
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      end
    end

    context "endpoint is current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        save_ui_case(x, path: "/posts/1") do
          expect(call("/posts/1", method: :patch, params: { post: { title: "bar" } })[0]).to eq(200)
        end
      end
    end

    context "endpoint matches the first part of current" do
      it "transforms" do |x|
        expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)

        save_ui_case(x, path: "/posts/1/related") do
          expect(call("/posts", method: :post, params: { post: { title: "bar" } })[0]).to eq(200)
        end
      end
    end
  end
end
