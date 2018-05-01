# frozen_string_literal: true

require "pakyow/support/deep_freeze"

require "pakyow/data/sources/ephemeral"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscribers

      attr_reader :subscribers

      def initialize(containers:, subscribers:)
        @subscribers = subscribers
        @subscribers.lookup = self

        containers.each do |container|
          container.sources.each do |source|
            define_singleton_method source.__class_name.name do
              Proxy.new(
                container.source_instance(
                  source.__class_name.name
                ),

                @subscribers
              )
            end
          end
        end
      end

      def ephemeral(type, id: nil)
        Proxy.new(
          Sources::Ephemeral.new(type, id: id),
          @subscribers
        )
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
