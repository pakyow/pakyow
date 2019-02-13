# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Data
    class Error < Pakyow::Error
    end

    class ConnectionError < Error
      def contextual_message
        String.new(
          <<~MESSAGE
            Connection for #{@context.type}.#{@context.name} could not be established.
          MESSAGE
        )
      end
    end

    class ConstraintViolation < Error
      class_state :messages, default: {
        associate_many_missing: "can't associate results as `{association}' because at least one value could not be found",
        associate_missing: "can't find associated {source} with {field} of `{value}'",
        associate_multiple: "can't associate multiple results as `{association}'",
        dependent_delete: "can't delete {source} because of {count} dependent {dependent}"
      }.freeze
    end

    class MissingAdapter < Error
    end

    class NotNullViolation < Error
      class_state :messages, default: {
        default: "`{attribute}' is a required attribute"
      }.freeze
    end

    class QueryError < Error
    end

    class Rollback < Error
    end

    class TypeMismatch < Error
      class_state :messages, default: {
        default: "can't convert `{type}' into {mapping}",
        associate_many_not_object: "can't associate results as `{association}' because at least one value is not a Pakyow::Data::Object",
        associate_many_wrong_source: "can't associate results as `{association}' because at least one value did not originate from {source}",
        associate_unknown_object: "can't associate an object with an unknown source as `{association}'",
        associate_wrong_object: "can't associate an object from {source} as `{association}'",
        associate_wrong_source: "can't associate {source} as `{association}'",
        associate_wrong_type: "can't associate {type} as `{association}'"
      }.freeze
    end

    class UniqueViolation < Error
    end

    class UnknownAdapter < Error
      class_state :messages, default: {
        default: "`{type}' is not a known adapter"
      }.freeze
    end

    class UnknownAttribute < Error
      class_state :messages, default: {
        default: "`{attribute}' is not a known attribute for {source}"
      }.freeze
    end

    class UnknownAssociation < Error
      def contextual_message
        if associations.any?
          String.new(
            <<~MESSAGE
              The following associations exist for #{@context.__object_name.name}:
            MESSAGE
          ).tap do |message|
            associations.each do |association|
              message << "  * #{association.name}"
            end
          end
        else
          String.new(
            <<~MESSAGE
              No associations exist for #{@context.__object_name.name}.
            MESSAGE
          )
        end
      end

      private

      def associations
        @context.associations.values.flatten
      end
    end

    class UnknownCommand < Error
      class_state :messages, default: {
        default: "`{command}' is not a known command"
      }.freeze

      def contextual_message
        if commands.any?
          String.new(
            <<~MESSAGE
              The following commands are defined for #{@context.__object_name.name}:
            MESSAGE
          ).tap do |message|
            commands.keys.each do |command|
              message << "  * #{command}\n"
            end
          end
        else
          String.new(
            <<~MESSAGE
              No commands are defined for #{@context.__object_name.name}.
            MESSAGE
          )
        end
      end

      private

      def commands
        @context.commands
      end
    end

    class UnknownSource < Error
      class_state :messages, default: {
        default: "unknown source `{association_source}' for association: {source} {association_type} {association_name}"
      }.freeze

      def contextual_message
        if sources.any?
          String.new(
            <<~MESSAGE
              The following sources are defined:
            MESSAGE
          ).tap do |message|
            sources.keys.each do |source|
              message << "  * #{source}\n"
            end
          end
        else
          String.new(
            <<~MESSAGE
              No sources are defined.
            MESSAGE
          )
        end
      end

      private

      def sources
        @context.sources
      end
    end
  end
end
