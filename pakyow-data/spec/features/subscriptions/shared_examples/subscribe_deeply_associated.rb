RSpec.shared_examples :subscription_subscribe_deeply_associated do
  describe "subscribing to a query that includes deeply associated data" do
    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    include_context "testable app"

    let :app_definition do
      Pakyow.config.data.default_adapter = :sql
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter

      Proc.new do
        Pakyow.after :configure do
          config.data.connections.sql[:default] = "sqlite::memory"
        end

        source :posts do
          primary_id

          attribute :title, :string

          has_many :comments
        end

        source :comments do
          primary_id

          attribute :title, :string

          has_many :tags
        end

        source :tags do
          primary_id

          attribute :name, :string
        end

        resource :posts, "/posts" do
          skip_action :verify_same_origin
          skip_action :verify_authenticity_token

          collection do
            post "subscribe" do
              data.posts.by_id(1).including(:comments) {
                including(:tags)
              }.subscribe(:post_subscriber, handler: TestHandler)
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

      @post = Pakyow.apps.first.data.posts.create(title: "post").one
      @comment = Pakyow.apps.first.data.comments.create(post: @post, title: "post").one
      Pakyow.apps.first.data.tags.create(comment: @comment, title: "foo")
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

    it "subscribes" do
      subscribe!
    end
  end
end
