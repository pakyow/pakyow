RSpec.shared_examples :subscription_subscribe_associated do
  describe "subscribing to a query that includes data associated via has_many" do
    before do
      local = self
      Pakyow.configure do
        config.data.default_adapter = :sql
        config.data.subscriptions.adapter = local.data_subscription_adapter
        config.data.subscriptions.adapter_settings = local.data_subscription_adapter_settings
        config.data.connections.sql[:default] = "sqlite::memory"
      end
    end

    include_context "app"

    let :handler do
      handler = Class.new {
        def initialize(app)
          @app = app
        end

        def call(*); end
      }

      stub_const("StubbedHandler", handler)

      handler
    end

    let :app_def do
      local = self

      Proc.new do
        source :posts do
          attribute :title, :string

          has_many :comments
        end

        source :comments do
          attribute :title, :string
        end

        resource :posts, "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          collection do
            post "subscribe" do
              data.posts.by_id(1).including(:comments).subscribe(:post_subscriber, handler: local.handler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end

        resource :comments, "/comments" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          create do
            verify do
              required :comment do
                required :title
                optional :post_id, :integer
              end
            end

            data.comments.create(params[:comment])
          end

          update do
            verify do
              required :id
              required :comment do
                required :title
                optional :post_id, :integer
              end
            end

            data.comments.by_title(params[:id]).update(params[:comment])
          end

          delete do
            data.comments.by_title(params[:id]).delete
          end
        end
      end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end

      @post = Pakyow.apps.first.data.posts.create(title: "post").one
    end

    after do
      unsubscribe!
    end

    def subscribe!
      response = call("/posts/subscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    def unsubscribe!
      response = call("/posts/unsubscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    context "when an object covered by the association is created" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the association is updated" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "calls the handler" do
          call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })

          subscribe!
          call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
          expect_any_instance_of(handler).to receive(:call)
          response = call("/comments/bar", method: :patch, params: { comment: { title: "baz" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object covered by the association is updated and now uncovered" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })

        post = Pakyow.apps.first.data.posts.create(title: "another post").one

        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "bar", post_id: post.id } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "does not call the handler" do
          call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })

          post = Pakyow.apps.first.data.posts.create(title: "another post").one

          subscribe!
          call("/comments/foo", method: :patch, params: { comment: { title: "foo", post_id: post.id } })
          expect_any_instance_of(handler).not_to receive(:call)
          response = call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object not previously covered by the association is updated and now covered" do
      it "calls the handler" do
        Pakyow.apps.first.data.posts.create(title: "another post")
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id + 1 } })

        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "foo", post_id: 1 } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the association is deleted" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/comments/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is created" do
      it "does not call the handler" do
        post = Pakyow.apps.first.data.posts.create(title: "another post").one

        subscribe!
        expect_any_instance_of(handler).to_not receive(:call)
        response = call("/comments", method: :post, params: { comment: { title: "foo", post_id: post.id } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is updated and still not covered" do
      it "does not call the handler" do
        Pakyow.apps.first.data.posts.create(title: "another post")
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id + 1 } })

        subscribe!
        expect_any_instance_of(handler).to_not receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is deleted" do
      it "does not call the handler" do
        Pakyow.apps.first.data.posts.create(title: "another post")
        call("/comments", method: :post, params: { comment: { title: "foo", post_id: @post.id + 1 } })

        subscribe!
        expect_any_instance_of(handler).to_not receive(:call)
        response = call("/comments/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end
  end

  describe "subscribing to a query that includes data associated via belongs_to" do
    before do
      local = self
      Pakyow.configure do
        config.data.default_adapter = :sql
        config.data.subscriptions.adapter = local.data_subscription_adapter
        config.data.subscriptions.adapter_settings = local.data_subscription_adapter_settings
        config.data.connections.sql[:default] = "sqlite::memory"
      end
    end

    include_context "app"

    let :handler do
      handler = Class.new {
        def initialize(app)
          @app = app
        end

        def call(*); end
      }

      stub_const("StubbedHandler", handler)

      handler
    end

    let :app_def do
      local = self

      Proc.new do
        source :posts do
          attribute :title, :string
        end

        source :users do
          attribute :name, :string

          has_many :posts, dependent: :delete
        end

        resource :posts, "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          collection do
            post "subscribe" do
              data.posts.by_id(1).including(:user).subscribe(:post_subscriber, handler: local.handler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end

        resource :users, "/users" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          create do
            verify do
              required :user do
                required :name
              end
            end

            data.users.create(params[:user])
          end

          update do
            verify do
              required :id
              required :user do
                required :name
              end
            end

            data.users.by_id(params[:id]).update(params[:user])
          end

          delete do
            data.users.by_id(params[:id]).delete
          end
        end
      end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end

      @user = Pakyow.apps.first.data.users.create(name: "user1").one
      @post = Pakyow.apps.first.data.posts.create(title: "post", user: @user).one
    end

    after do
      unsubscribe!
    end

    def subscribe!
      response = call("/posts/subscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    def unsubscribe!
      response = call("/posts/unsubscribe", method: :post)
      expect(response[0]).to eq(200)
    end

    context "when an object covered by the association is updated" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/users/#{@user.id}", method: :patch, params: { user: { name: "user2" } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "calls the handler" do
          subscribe!
          call("/users/#{@user.id}", method: :patch, params: { user: { name: "user2" } })
          expect_any_instance_of(handler).to receive(:call)
          response = call("/users/#{@user.id}", method: :patch, params: { user: { name: "user3" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object covered by the association is deleted" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(handler).to receive(:call)
        response = call("/users/#{@user.id}", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is created" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(handler).to_not receive(:call)
        response = call("/users", method: :post, params: { user: { name: "user2" } })
        expect(response[0]).to eq(200)
      end
    end
  end
end
