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
      attr_reader :object

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

      class << self
        attr_reader :scope

        def make(name, state: nil, &block)
          klass = const_for_binder_named(Class.new(self), name)

          klass.class_eval do
            @scope = name
            class_eval(&block) if block_given?
          end

          klass
        end

        # TODO: combine with Router#const_for_router_named and move to support
        def const_for_binder_named(binder_class, name)
          return binder_class if name.nil?

          # convert snake case to camel case
          class_name = "#{name.to_s.split('_').map(&:capitalize).join}Binder"

          if Object.const_defined?(class_name)
            binder_class
          else
            Object.const_set(class_name, binder_class)
          end
        end
      end
    end
  end
end
