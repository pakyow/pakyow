require "pakyow/support/class_maker"

module Pakyow
  module Presenter
    class BinderParts
      attr_reader :parts

      def initialize
        @parts = {}
      end

      def define_part(name, value)
        @parts[name] = value
      end

      def content?
        @parts.include?(:content)
      end

      def content
        @parts[:content]
      end

      def non_content_parts
        @parts.reject { |name, _| name == :content }
      end
    end
  end
end

module Pakyow
  module Presenter
    class Binder
      extend Support::ClassMaker
      CLASS_MAKER_BASE = "Binder".freeze

      attr_reader :object

      include Helpers

      def initialize(object)
        @object = object
        @parts = {}
      end

      def include?(key)
        respond_to?(key) || @object.include?(key)
      end

      def [](key)
        if respond_to?(key)
          value = __send__(key)

          if parts?(key)
            parts_for(key)
          else
            value
          end
        else
          @object[key]
        end
      end

      def part(name)
        parts_for(caller_locations(1,1)[0].label.to_sym).define_part(name, yield)
      end

      private

      def parts?(name)
        @parts.include?(name)
      end

      def parts_for(name)
        @parts[name] ||= BinderParts.new
      end
    end
  end
end
