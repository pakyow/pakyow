RSpec.describe "defining resources" do
  include_context "app"

  context "when the resource is defined at the top level" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          list do
            send "post list"
          end
        end
      }
    end

    it "defines the resource" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post list")
    end
  end

  context "when the resource is nested within another resource" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          resource :comments, "/comments" do
            list do
              send "post #{params[:post_id]} comment list"
            end
          end
        end
      }
    end

    it "defines the resource" do
      res = call("/posts/1/comments")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 comment list")
    end
  end

  context "when the resource is deeply nested within another resource" do
    let :app_def do
      Proc.new {
        resource :channels, "/channels" do
          resource :posts, "/posts" do
            resource :comments, "/comments" do
              list do
                send "channel #{params[:channel_id]} post #{params[:post_id]} comment list"
              end
            end
          end
        end
      }
    end

    it "defines the resource" do
      res = call("/channels/1/posts/2/comments")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("channel 1 post 2 comment list")
    end
  end

  context "when the resource is defined with actions" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          action :validate

          def validate
            send "validate"
          end

          list do
            send "list"
          end
        end
      }
    end

    it "calls the resource's actions" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("validate")
    end

    context "and the resource route defines its own actions" do
      let :app_def do
        Proc.new {
          resource :posts, "/posts" do
            action :validate
            action :foo, only: [:list]

            def validate
              $calls << :validate
            end

            def foo
              $calls << :foo
            end

            list do
              send "list"
            end
          end
        }
      end

      before do
        $calls = []
      end

      it "calls all the actions" do
        res = call("/posts")
        expect(res[0]).to eq(200)
        expect(res[2]).to eq("list")
        expect($calls[0]).to eq(:validate)
        expect($calls[1]).to eq(:foo)
      end
    end
  end

  context "when the resource is defined partially" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          list do
          end
        end
      }
    end

    it "does not respond to undefined routes" do
      expect(call("/posts/new")[0]).to eq(404)
    end
  end

  context "when the resource is extended with member routes" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          show do
            send "show"
          end

          member do
            get :foo, "/foo" do
              send "foo"
            end
          end
        end
      }
    end

    it "properly defines the member routes" do
      expect(call("/posts/123/foo")[0]).to eq(200)
      expect(call("/posts/123/foo")[2]).to eq("foo")
    end

    it "does not conflict with the show route" do
      expect(call("/posts/123")[0]).to eq(200)
      expect(call("/posts/123")[2]).to eq("show")
    end
  end

  context "when the resource is extended with collection routes" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          show do
            send "show"
          end

          collection do
            get "/foo" do
              send "foo"
            end
          end
        end
      }
    end

    it "properly defines the collection routes" do
      expect(call("/posts/foo")[0]).to eq(200)
      expect(call("/posts/foo")[2]).to eq("foo")
    end

    it "does not conflict with the show route" do
      expect(call("/posts/123")[0]).to eq(200)
      expect(call("/posts/123")[2]).to eq("show")
    end
  end

  context "when the resource is defined with a regexp" do
    it "needs tests"
  end

  context "when the resource is defined with a custom matcher" do
    it "needs tests"
  end

  context "when the resource is defined with a url param" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts", param: :slug do
          show do
            send "post #{params[:slug]} show"
          end
        end
      }
    end

    it "properly paramaterizes the url" do
      res = call("/posts/foo")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post foo show")
    end
  end

  context "when a nested resource is defined with a url param" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          resource :comments, "/comments", param: :slug do
            show do
              send "comment #{params[:slug]} show"
            end
          end
        end
      }
    end

    it "properly paramaterizes the url" do
      res = call("/posts/foo/comments/bar")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("comment bar show")
    end
  end

  describe "the defined resource" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          disable_protection :csrf

          list do
            send "post list"
          end

          new do
            send "post new"
          end

          create do
            send "post create"
          end

          edit do
            send "post #{params[:id]} edit"
          end

          update do
            send "post #{params[:id]} update"
          end

          replace do
            send "post #{params[:id]} replace"
          end

          delete do
            send "post #{params[:id]} delete"
          end

          show do
            send "post #{params[:id]} show"
          end
        end
      }
    end

    it "exposes its param" do
      expect(Test::Controllers::Posts.param).to eq(:id)
    end

    it "exposes its nested param" do
      expect(Test::Controllers::Posts.nested_param).to eq(:post_id)
    end

    it "can have a list action" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post list")
    end

    it "can have a new action" do
      res = call("/posts/new")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post new")
    end

    it "can have a create action" do
      res = call("/posts", method: :post)
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post create")
    end

    it "can have a edit action" do
      res = call("/posts/1/edit")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 edit")
    end

    it "can have a update action" do
      res = call("/posts/1", method: :patch)
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 update")
    end

    it "can have a replace action" do
      res = call("/posts/1", method: :put)
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 replace")
    end

    it "can have a delete action" do
      res = call("/posts/1", method: :delete)
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 delete")
    end

    it "can have a show action" do
      res = call("/posts/1")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post 1 show")
    end
  end

  describe "routing to a path with an extension" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          list do
            send "post list"
          end

          show do
            send "post #{params[:id]} show"
          end
        end
      }
    end

    it "calls the appropriate route" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("post list")

      res = call("/posts.html")
      expect(res[0]).to eq(404)
    end
  end

  describe "defining the same nested resource multiple times" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          resource :comments, "/comments" do
            list
          end

          resource :comments, "/comments" do
            show
          end
        end
      }
    end

    let :controllers do
      Pakyow.apps.first.controllers.definitions
    end

    it "adds routes to the existing resource" do
      expect(controllers.count).to eq(1)
      expect(controllers[0].children.count).to eq(1)
      expect(controllers[0].children[0].routes.values.flatten.count).to eq(2)
      expect(controllers[0].children[0].routes.values.flatten.map(&:name)).to eq([:list, :show])
    end
  end

  describe "defining the same top level resource multiple times" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          list
        end

        resource :posts, "/posts" do
          show
        end
      }
    end

    let :controllers do
      Pakyow.apps.first.controllers.definitions
    end

    it "adds routes to the existing resource" do
      expect(controllers.count).to eq(1)
      expect(controllers[0].routes.values.flatten.count).to eq(2)
      expect(controllers[0].routes.values.flatten.map(&:name)).to eq([:list, :show])
    end
  end

  describe "defining instance methods on a resource" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          list do
            send(foo); halt
          end

          def foo
            "foo"
          end
        end
      }
    end

    it "makes the instance methods callable" do
      expect(call("/posts")[2]).to eq("foo")
    end
  end

  describe "defining instance methods on a nested resource" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          resource :comments, "/comments" do
            list do
              send(foo); halt
            end

            def foo
              "foo"
            end
          end
        end
      }
    end

    it "makes the instance methods callable" do
      expect(call("/posts/1/comments")[2]).to eq("foo")
    end
  end

  describe "defining show before new" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts" do
          show do
            send "show"
          end

          new do
            send "new"
          end
        end
      }
    end

    it "does not call show for new" do
      expect(call("/posts/new")[2]).to eq("new")
    end
  end
end
