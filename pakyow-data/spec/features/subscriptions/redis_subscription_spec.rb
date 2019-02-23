require_relative "shared_examples"

RSpec.describe "using data subscriptions with the redis adapter" do
  let :data_subscription_adapter do
    :redis
  end

  let :data_subscription_adapter_settings do
    Pakyow.config.redis.dup
  end

  after do
    if defined?(Redis)
      Redis.new.flushdb
    end
  end

  include_examples "data subscriptions"

  describe "cleaning up" do
    before do
      require "redis"
      Pakyow.config.data.subscriptions.adapter = data_subscription_adapter
      Pakyow.config.data.subscriptions.adapter_settings = data_subscription_adapter_settings
    end

    include_context "app"

    let :subscribers do
      Pakyow.apps[0].data.subscribers
    end

    def keys
      Redis.new.keys("*")
    end

    it "cleans up subscriptions with no more subscribers" do
      keys_initial = keys
      subscribers.register_subscriptions([{ foo: "bar", source: "tests" }], subscriber: :baz)
      expect((keys - keys_initial).count).to eq(5)
      subscribers.expire(:baz, 1)

      sleep 2

      subscribers.adapter.cleanup
      expect(keys.length).to eq(0)
    end

    context "subscription is added to an expiring subscriber" do
      it "cleans up the subscription when the subscriber expires" do
        keys_initial = keys
        subscribers.register_subscriptions([{ foo: "bar", source: "tests" }], subscriber: :baz)
        subscribers.expire(:baz, 1)
        subscribers.register_subscriptions([{ baz: "baz", source: "tests" }], subscriber: :baz)
        expect((keys - keys_initial).count).to eq(5)

        sleep 2

        subscribers.adapter.cleanup
        expect(keys.length).to eq(0)
      end
    end
  end
end
