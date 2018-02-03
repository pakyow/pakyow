# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscribers

      attr_reader :subscribers

      def initialize(models, subscribers)
        @models, @subscribers = models, subscribers
        subscribers.lookup = self

        @models.each do |key, model|
          define_singleton_method key do
            Proxy.new(
              model.new(
                Pakyow.relation(model.__class_name.name, model.adapter, model.connection)
              ), @subscribers
            )
          end
        end
      end

      def model(name)
        @models[name]
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
    end
  end
end
