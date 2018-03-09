# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscribers

      attr_reader :subscribers

      def initialize(models, subscribers)
        @subscribers = subscribers
        @subscribers.lookup = self

        models.each do |model|
          define_singleton_method model.plural_name do
            Proxy.new(
              Source.new(
                model: model,
                relation: Pakyow.relation(
                  model.plural_name,
                  model.adapter,
                  model.connection
                )
              ), @subscribers
            )
          end
        end
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
