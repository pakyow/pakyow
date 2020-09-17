RSpec.shared_examples :subscription_persist do
  before do
    require "redis"

    local = self
    Pakyow.configure do
      config.data.subscriptions.adapter = local.data_subscription_adapter
      config.data.subscriptions.adapter_settings = local.data_subscription_adapter_settings
    end
  end

  include_context "app"

  let :subscribers do
    Pakyow.apps[0].data.subscribers
  end

  let :source do
    "tests"
  end

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
        expect_any_instance_of(handler).to receive(:call)
        subscribers.did_mutate(source)
      end
    end
  end
end
