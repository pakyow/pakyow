RSpec.describe "presenting a view that defines an anchor endpoint in a nested binding scope" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new {
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts.including(:comments)
          render "/endpoints/anchor/nested_scope"
        end

        show do
          expose :posts, data.posts.by_id(params[:id].to_i).including(:comments)
          render "/endpoints/anchor/nested_scope"
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
            render "/endpoints/anchor/nested_scope"
          end
        end

        resources :comments, "/comments" do
          disable_protection :csrf

          show do
            # intentionally empty
          end

          create do
            verify do
              required :post_id
              required :comment do
                required :title
              end
            end

            params[:comment][:post_id] = params[:post_id].to_i
            data.comments.create(params[:comment])
          end
        end
      end

      presenter "/endpoints/anchor/nested_scope" do
        perform do
          find(:post).present(posts)
        end
      end

      source :posts do
        primary_id

        attribute :title

        has_many :comments
      end

      source :comments do
        primary_id

        attribute :title
      end
    }
  end

  context "binding is bound to" do
    it "transforms" do |x|
      expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
      expect(call("/posts/1/comments", method: :post, params: { comment: { title: "foo" } })[0]).to eq(200)

      save_ui_case(x, path: "/posts") do
        expect(call("/posts/1/comments", method: :post, params: { comment: { title: "bar" } })[0]).to eq(200)
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
