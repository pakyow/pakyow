# frozen_string_literal: true

require "pakyow/support/deep_freeze"

require "pakyow/data/errors"
require "pakyow/data/proxy"
require "pakyow/data/sources/ephemeral"

module Pakyow
  module Data
    class Lookup
      extend Support::DeepFreeze
      unfreezable :subscribers

      # @api private
      attr_reader :subscribers, :sources

      def initialize(containers:, subscribers:)
        @subscribers = subscribers
        @subscribers.lookup = self

        @sources = {}
        containers.each do |container|
          container.sources.each do |source|
            @sources[source.__object_name.name] = source
            define_singleton_method source.__object_name.name do
              Proxy.new(
                container.source(
                  source.__object_name.name
                ),

                @subscribers
              )
            end
          end
        end

        validate!
      end

      def ephemeral(type, **qualifications)
        Proxy.new(
          Sources::Ephemeral.new(type, **qualifications),
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

      private

      def validate!
        validate_associated_sources!
      end

      def validate_associated_sources!
        @sources.values.each do |source|
          source.associations.values.flatten.each do |association|
            unless @sources.key?(association[:source_name])
              raise(
                UnknownSource.new("Unknown source `#{association[:source_name]}` for association: #{source.__object_name.name} #{association[:type]} #{association[:access_name]}").tap do |error|
                  error.context = self
                end
              )
            end
          end
        end
      end
    end
  end
end
