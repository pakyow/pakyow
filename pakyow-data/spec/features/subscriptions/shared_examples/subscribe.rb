RSpec.shared_examples :subscription_subscribe do
  describe "subscribing to a query" do
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
          attribute :body, :string

          subscribe :by_title, title: :__arg0__

          def by_title(title)
            where(title: title)
          end
        end

        source :comments do
          primary_id

          attribute :title, :string

          def by_title(title)
            where(title: title)
          end
        end

        resources :posts, "/posts" do
          skip_action :verify_same_origin
          skip_action :verify_authenticity_token

          create do
            verify do
              required :post do
                required :title
                optional :body
              end
            end

            data.posts.create(params[:post])
          end

          update do
            verify do
              required :id

              required :post do
                optional :title
                optional :body
              end
            end

            data.posts.by_title(params[:id]).update(params[:post])
          end

          delete do
            data.posts.by_title(params[:id]).delete
          end

          collection do
            post "subscribe" do
              data.posts.subscribe(:post_subscriber, handler: TestHandler)
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
              end
            end

            data.comments.create(params[:comment])
          end

          update do
            verify do
              required :comment do
                required :title
              end
            end

            data.comments.by_title(params[:comment_id]).update(params[:comment])
          end

          delete do
            data.comments.by_title(params[:comment_id]).delete
          end
        end
      end
    end

    before do
      allow(Thread).to receive(:new).and_yield
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

    context "when an object covered by the query is created" do
      it "calls the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts", method: :post, params: { post: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is updated" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "foo" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :patch, params: { post: { title: "bar" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object covered by the query is deleted" do
      it "calls the handler" do
        call("/posts", method: :post, params: { post: { title: "foo" } })

        subscribe!
        expect_any_instance_of(TestHandler).to receive(:call)
        response = call("/posts/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is created" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments", method: :post, params: { comment: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is updated" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments/foo", method: :patch, params: { comment: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end

    context "when an object not covered by the query is deleted" do
      it "does not call the handler" do
        subscribe!
        expect_any_instance_of(TestHandler).to_not receive(:call)
        response = call("/comments/foo", method: :delete)
        expect(response[0]).to eq(200)
      end
    end
  end
end
