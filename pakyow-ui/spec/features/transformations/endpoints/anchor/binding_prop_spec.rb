RSpec.describe "presenting a view that defines an anchor endpoint that is a binding prop" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    local_extensions = extensions

    Proc.new {
      instance_exec(&$ui_app_boilerplate)
      instance_exec(&local_extensions)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/endpoints/anchor/binding_prop"
        end

        show do
          expose :posts, data.posts.by_id(params[:id])
          render "/endpoints/anchor/binding_prop"
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
            render "/endpoints/anchor/binding_prop"
          end
        end
      end

      presenter "/endpoints/anchor/binding_prop" do
        perform do
          find(:post).present(posts)
        end
      end

      source :posts do
        primary_id

        attribute :title
      end
    }
  end

  let :extensions do
    Proc.new do; end
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

    context "binder exists" do
      let :extensions do
        Proc.new do
          binder :post do
            def title
              object[:title].to_s.reverse
            end
          end
        end
      end

      it "transforms" do |x|
        save_ui_case(x, path: "/posts") do
          expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
        end
      end

      context "binder sets the href" do
        let :extensions do
          Proc.new do
            binder :post do
              def title
                part :content do
                  object[:title].to_s.reverse
                end

                part :href do
                  "overridden"
                end
              end
            end
          end
        end

        it "transforms" do |x|
          save_ui_case(x, path: "/posts") do
            expect(call("/posts", method: :post, params: { post: { title: "foo" } })[0]).to eq(200)
          end
        end
      end
    end
  end
end
