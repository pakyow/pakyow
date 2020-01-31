# frozen_string_literal: true

module Pakyow
  module Support
    # Represents a deprecation for `targets`, with a given `solution`.
    #
    class Deprecation
      def initialize(*targets, solution:)
        @targets, @solution = targets, solution
      end

      # Returns the deprecation message and solution as a string.
      #
      # @example
      #
      #   Deprecation.new(Foo, :bar, solution: "use `baz'").to_s
      #   => `Foo::bar' is deprecated; solution: use `baz'
      #
      #   Deprecation.new(Foo.new, :bar, solution: "use `baz'").to_s
      #   => `Foo#bar' is deprecated; solution: use `baz'
      #
      #   Deprecation.new("`foo.rb'", solution: "rename to `bar.rb'").to_s
      #   => `foo.rb' is deprecated; solution: rename to `baz.rb'
      #
      def to_s
        build_full_message.dup
      end

      private def build_full_message
        unless defined?(@__full_message)
          @__full_message = "#{build_deprecation_message}; solution: #{build_solution}"
        end

        @__full_message
      end

      private def build_deprecation_message
        unless defined?(@__deprecation_message)
          initial_target = @targets.first
          @__deprecation_message = case initial_target
          when Class
            build_deprecation_message_for_class(initial_target)
          when Symbol
            build_deprecation_message_for_method(initial_target)
          when String
            build_deprecation_message_for_custom(initial_target)
          else
            build_deprecation_message_for_object(initial_target)
          end
        end

        @__deprecation_message
      end

      private def build_deprecation_message_for_class(klass)
        target = if @targets.count > 1
          "#{klass}::#{@targets[1]}"
        else
          "#{klass}"
        end

        "`#{target}' is deprecated"
      end

      private def build_deprecation_message_for_method(method)
        "`#{method}' is deprecated"
      end

      private def build_deprecation_message_for_custom(string)
        "#{string} is deprecated"
      end

      private def build_deprecation_message_for_object(object)
        target = if @targets.count > 1
          "#{object.class}##{@targets[1]}"
        else
          "#{object.class}"
        end

        "`#{target}' is deprecated"
      end

      private def build_solution
        @solution
      end
    end
  end
end
