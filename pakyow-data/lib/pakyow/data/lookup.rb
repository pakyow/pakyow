# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscribers

      def initialize(models, subscribers)
        @models, @subscribers = models, subscribers
        subscribers.lookup = self
      end

      def unsubscribe(subscriber)
        @subscribers.unsubscribe(subscriber)
      end

      def expire(subscriber, seconds)
        @subscribers.expire(subscriber, seconds)
      end

      def persist(subscriber)
        @subscribers.persist(subscriber)
      end

      def method_missing(name)
        if model = @models[name]
          # FIXME: protect against missing containers (maybe define a lookup method on the environment)
          # TODO: handle edge-cases around connections not being defined... just spent some time tracking down a bug caused by it
          container = Pakyow.database_containers[model.adapter || Pakyow.config.data.default_adapter][model.connection]
          ModelProxy.new(model.new(container.relations[model.__class_name.name]), @subscribers)
        else
          nil
        end
      end
    end
  end
end
