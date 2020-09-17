RSpec.shared_examples :subscription_subscribe_many do
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
      class << self
        attr_reader :subscription

        def subscription=(subscription)
          @subscription = subscription
        end
      end

      def initialize(app)
        @app = app
      end

      def call(*); end
    }

    stub_const("StubbedHandler", handler)

    handler
  end

  context "expiring subscriber exists with a subscription" do
    before do
      subscribers.register_subscriptions(
        [{ foo: "bar", source: source, handler: handler }], subscriber: :foo
      )

      subscribers.expire(:foo, 30)
    end

    context "second subscriber subscribes to the same subscription" do
      before do
        subscribers.register_subscriptions(
          [{ foo: "bar", source: source, handler: handler }], subscriber: :bar
        )
      end

      it "triggers a mutation" do
        double = instance_double(handler)
        allow(handler).to receive(:new).and_return(double)
        expect(double).to receive(:call).once
        subscribers.did_mutate(source)
      end
    end
  end

  context "subscriber exists with a subscription" do
    before do
      subscribers.register_subscriptions(
        [{ foo: "bar", source: source, handler: handler }], subscriber: :foo
      )
    end

    context "second subscriber subscribes to the same subscription, then is expired" do
      before do
        subscribers.register_subscriptions(
          [{ foo: "bar", source: source, handler: handler }], subscriber: :bar
        )

        subscribers.expire(:bar, 30)
      end

      it "triggers a mutation" do
        double = instance_double(handler)
        allow(handler).to receive(:new).and_return(double)
        expect(double).to receive(:call).once
        subscribers.did_mutate(source)
      end
    end

    context "subscriber is expired, then another subscription is created, then subscriber is persisted" do
      before do
        subscribers.expire(:foo, 30)

        subscribers.register_subscriptions(
          [{ bar: "baz", source: source, handler: handler }], subscriber: :foo
        )

        subscribers.persist(:foo)
      end

      context "second subscriber subscribes to the second subscription, then is expired" do
        before do
          subscribers.register_subscriptions(
            [{ bar: "baz", source: source, handler: handler }], subscriber: :bar
          )

          subscribers.expire(:bar, 30)
        end

        it "triggers a mutation" do
          double = instance_double(handler)
          allow(handler).to receive(:new).and_return(double)
          expect(double).to receive(:call).twice
          subscribers.did_mutate(source)
        end
      end
    end
  end

  context "subscriber is set to expire" do
    before do
      subscribers.expire(:foo, 30)
    end

    context "subscription is registered for the expiring subscriber" do
      before do
        subscribers.register_subscriptions(
          [{ foo: "bar", source: source, handler: handler }], subscriber: :foo
        )
      end

      context "expiring subscriber is persisted" do
        before do
          subscribers.persist(:foo)
        end

        context "subscription is registered for a second subscriber" do
          before do
            subscribers.register_subscriptions(
              [{ foo: "bar", source: source, handler: handler }], subscriber: :bar
            )
          end

          context "second subscriber is set to expire" do
            before do
              subscribers.expire(:bar, 30)
            end

            context "first subscriber is set to expire" do
              before do
                subscribers.expire(:foo, 30)
              end

              context "second subscriber is persisted" do
                before do
                  subscribers.persist(:bar)
                end

                it "triggers a mutation" do
                  double = instance_double(handler)
                  allow(handler).to receive(:new).and_return(double)
                  expect(double).to receive(:call).once
                  subscribers.did_mutate(source)
                end
              end
            end
          end
        end
      end
    end
  end
end
