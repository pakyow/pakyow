# frozen_string_literal: true

require_relative "errors"
require_relative "proxy"
require_relative "sources/ephemeral"

module Pakyow
  module Data
    class Lookup
      # @api private
      attr_reader :subscribers, :sources, :containers

      def initialize(containers:, subscribers:, app:)
        @subscribers = subscribers
        @subscribers.lookup = self
        @app = app

        @sources = {}
        @containers = containers
        @containers.each do |container|
          container.sources.each do |source|
            @sources[source.object_name.name] = source
            define_singleton_method source.object_name.name do
              Proxy.new(
                container.source(
                  source.object_name.name
                ),
                @subscribers, @app
              )
            end
          end
        end

        validate!
      end

      def ephemeral(type, **qualifications)
        Proxy.new(
          Sources::Ephemeral.new(type, **qualifications),
          @subscribers, @app
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
            association.dependent_source_names.compact.each do |source_name|
              unless @sources.key?(source_name)
                raise(
                  UnknownSource.new_with_message(
                    source: source.object_name.name,
                    association_source: source_name,
                    association_type: association.specific_type,
                    association_name: association.name
                  ).tap do |error|
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
end
