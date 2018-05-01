RSpec.shared_examples :subscription_subscribe_associated_conditional do
  describe "subscribing to a query that includes associated data with a query" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    include_context "testable app"

    let :app_definition do
      Pakyow.config.data.default_adapter = :sql
      Pakyow.config.data.connections.sql[:default] = "sqlite::memory"
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter

      Proc.new do
        source :posts do
          primary_id

          attribute :title, :string

          has_many :comments
        end

        source :comments do
          primary_id

          attribute :title, :string
          attribute :body, :string
        end

        resources :posts, "/posts" do
          skip_action :verify_same_origin
          skip_action :verify_authenticity_token

          collection do
            post "subscribe" do
              data.posts.by_id(1).including(:comments) {
                by_title("foo")
              }.subscribe(:post_subscriber, handler: TestHandler)
            end

            post "unsubscribe" do
              data.subscribers.unsubscribe(:post_subscriber)
            end
          end
        end

        resources :comments, "/comments" do
          skip_action :verify_same_origin
          skip_action :verify_authenticity_token

          create do
            verify do
              required :comment do
                required :title
                required :body
                optional :post_id
              end
            end

            data.comments.create(params[:comment])
          end

          update do
            verify do
              required :id

              required :comment do
                optional :title
                optional :body
                optional :post_id
              end
            end

            data.comments.by_title(params[:id]).update(params[:comment])
          end

          remove do
            data.comments.by_title(params[:id]).delete
          end
        end
      end
    end

    before do
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
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the association is updated" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { body: "bar" } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "calls the handler" do
          call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })

          subscribe!
          call("/comments/foo", method: :patch, params: { comment: { body: "bar" } })
          expect_any_instance_of(TestHandler).to receive(:call)
          response = call("/comments/foo", method: :patch, params: { comment: { body: "baz" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object covered by the association is updated and now uncovered" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
        expect(response[0]).to eq(200)
      end

      context "when that object is updated again" do
        it "does not call the handler" do
          call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })

          subscribe!
          call("/comments/foo", method: :patch, params: { comment: { title: "bar" } })
          expect_any_instance_of(TestHandler).not_to receive(:call)
          response = call("/comments/foo", method: :patch, params: { comment: { title: "baz" } })
          expect(response[0]).to eq(200)
        end
      end
    end

    context "when an object not previously covered by the association is updated and now covered" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "bar", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/comments/bar", method: :patch, params: { comment: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the association is deleted" do
      it "calls the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/comments/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is created" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments", method: :post, params: { comment: { title: "bar", body: "foo", post_id: @post.id } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is updated and still not covered" do
      it "does not call the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })
        call("/comments", method: :post, params: { comment: { title: "bar", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments/bar", method: :patch, params: { comment: { title: "baz" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the association is deleted" do
      it "does not call the handler" do
        call("/comments", method: :post, params: { comment: { title: "foo", body: "foo", post_id: @post.id } })
        call("/comments", method: :post, params: { comment: { title: "bar", body: "foo", post_id: @post.id } })

        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments/bar", method: :delete)
        expect(response[0]).to eq(200)
      end
    end
  end
end
