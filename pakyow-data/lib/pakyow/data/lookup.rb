# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscriber_store

      def initialize(models, subscriber_store)
        @models, @subscriber_store = models, subscriber_store
        subscriber_store.lookup = self
      end

      def unsubscribe(subscriber)
        @subscriber_store.unsubscribe(subscriber)
      end

      def expire(subscriber, seconds)
        @subscriber_store.expire(subscriber, seconds)
      end

      def persist(subscriber)
        @subscriber_store.persist(subscriber)
      end

      def method_missing(name)
        if model = @models[name]
          # FIXME: protect against missing containers (maybe define a lookup method on the environment)
          container = Pakyow.database_containers[model.adapter || Pakyow.config.data.default_adapter][model.connection]
          ModelProxy.new(model.new(container.relations[model.name]), @subscriber_store)
        else
          nil
        end
      end
    end
  end
end
