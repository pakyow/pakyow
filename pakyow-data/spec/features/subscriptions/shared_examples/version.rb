RSpec.shared_examples :subscription_version do
  describe "versioning subscriptions" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

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

    let :app_def do
      Proc.new do
        source :posts do
          attribute :title, :string
        end

        resource :posts, "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          create do
            verify do
              required :post do
                required :title
                optional :body
              end
            end

            data.posts.create(params[:post])
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
      end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end
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

    it "calls the handler" do
      subscribe!
      expect_any_instance_of(TestHandler).to receive(:call)
      response = call("/posts", method: :post, params: { post: { title: "foo" } })
      expect(response[0]).to eq(200)
    end

    context "app version changes after subscribe" do
      it "does not call the handler" do
        subscribe!
        Pakyow.apps.first.config.data.subscriptions.version = "foo"
        expect_any_instance_of(TestHandler).not_to receive(:call)
        response = call("/posts", method: :post, params: { post: { title: "foo" } })
        expect(response[0]).to eq(200)
      end
    end
  end
end
