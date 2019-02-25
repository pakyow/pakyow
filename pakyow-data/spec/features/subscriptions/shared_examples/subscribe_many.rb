RSpec.shared_examples :subscription_subscribe_many do
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
    end

    TestHandler
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
        double = instance_double(TestHandler)
        allow(TestHandler).to receive(:new).and_return(double)
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
        double = instance_double(TestHandler)
        allow(TestHandler).to receive(:new).and_return(double)
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
          double = instance_double(TestHandler)
          allow(TestHandler).to receive(:new).and_return(double)
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
                  double = instance_double(TestHandler)
                  allow(TestHandler).to receive(:new).and_return(double)
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
