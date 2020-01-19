RSpec.shared_examples :subscription_expire do
  describe "expiring a subscription" do
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
      end
    end

    let :subscriber do
      SecureRandom.hex(24)
    end

    class TestHandler
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    before do
      allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
        block.call
      end
    end

    it "needs more tests"

    context "subscription has no active subscribers" do
      before do
        Pakyow.app(:test).data.posts.subscribe(subscriber, handler: TestHandler)
        Pakyow.app(:test).data.expire(subscriber, 5)
      end

      it "does not process the subscription" do
        expect_any_instance_of(Pakyow::Data::Subscribers).not_to receive(:process)
        Pakyow.app(:test).data.posts.create(title: "foo")
      end
    end

    context "subscription has an active subscriber" do
      before do
        Pakyow.app(:test).data.posts.subscribe(subscriber + "_1", handler: TestHandler)
        Pakyow.app(:test).data.posts.subscribe(subscriber + "_2", handler: TestHandler)
        Pakyow.app(:test).data.expire(subscriber + "_2", 5)
      end

      it "processes the subscription" do
        expect_any_instance_of(Pakyow::Data::Subscribers).to receive(:process)
        Pakyow.app(:test).data.posts.create(title: "foo")
      end
    end
  end
end
