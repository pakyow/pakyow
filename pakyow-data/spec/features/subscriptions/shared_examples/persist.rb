RSpec.shared_examples :subscription_persist do
  before do
    require "redis"
    Pakyow.config.data.subscriptions.adapter = data_subscription_adapter
    Pakyow.config.data.subscriptions.adapter_settings = data_subscription_adapter_settings
  end

  include_context "app"

  let :subscribers do
    Pakyow.apps[0].data.subscribers
  end

  let :source do
    "tests"
  end

  let :handler do
    stub_const "TestHandler", Class.new
    TestHandler.class_eval do
      def initialize(app)
        @app = app
      end

      def call(*); end
    end

    TestHandler
  end

  context "subscriber exists with a subscription" do
    before do
      subscribers.register_subscriptions(
        [{ foo: "bar", source: source, handler: handler }], subscriber: :foo
      )
    end

    context "subscriber is expired then persisted" do
      before do
        subscribers.expire(:foo, 1)
        subscribers.persist(:foo)
      end

      it "triggers mutations for both subscriptions" do
        expect_any_instance_of(TestHandler).to receive(:call)
        subscribers.did_mutate(source)
      end
    end
  end
end
