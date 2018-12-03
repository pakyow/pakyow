# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Data
    class Error < Pakyow::Error
    end

    class QueryError < Error
    end

    class ConstraintViolation < Error
    end

    class NotNullViolation < Error
    end

    class UniqueViolation < Error
    end

    class Rollback < Error
    end

    class TypeMismatch < Error
    end

    class UnknownAttribute < Error
    end

    class UnknownAssociation < Error
      def message
        if associations.any?
          String.new(
            <<~MESSAGE
              #{super}

              The following associations exist for `#{@context.__object_name.name}`:
            MESSAGE
          ).tap do |message|
            associations.each do |association|
              message << "  * #{association[:access_name]}"
            end
          end
        else
          String.new(
            <<~MESSAGE
              #{super}

              No associations exist for `#{@context.__object_name.name}`.
            MESSAGE
          )
        end
      end

      private

      def associations
        @context.associations.values.flatten
      end
    end

    class UnknownSource < Error
      def message
        if sources.any?
          String.new(
            <<~MESSAGE
              #{super}

              The following sources are defined:
            MESSAGE
          ).tap do |message|
            sources.keys.each do |source|
              message << "  * #{source}"
            end
          end
        else
          String.new(
            <<~MESSAGE
              #{super}

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
