# frozen_string_literal: true

module Pakyow
  module Support
    # Turns a module into an extension that can define and load complex behavior into objects.
    #
    # @example
    #   module SomeExtension
    #     extend Pakyow::Support::Extension
    #
    #     apply_extension do
    #       # This block will be evaluated in context of the including object.
    #     end
    #
    #     class_methods do
    #       # Define methods to add to the including object's class.
    #     end
    #
    #     prepend_methods do
    #       # Define methods to prepend to the including object.
    #     end
    #
    #     common_methods do
    #       # Define methods to add both to the including object and its class.
    #     end
    #
    #     # Define instance methods for the including object, like with a normal module.
    #   end
    #
    #   module SomeClass
    #     include SomeExtension
    #   end
    #
    # = Restrictions
    #
    # Extensions can be restricted to a particular object type. Loading the extension into an object
    # of a type other than the restricted type will cause a RuntimeError.
    #
    # @example
    #   class SomeBaseClass
    #     ...
    #   end
    #
    #   module SomeExtension
    #     extend Pakyow::Support::Extension
    #     restrict_extension SomeBaseClass
    #
    #     ...
    #   end
    #
    #   class SomeSubClass < SomeBaseClass
    #     include SomeExtension
    #
    #      ...
    #   end
    #
    #   class SomeOtherClass
    #     include SomeExtension
    #
    #     # => RuntimeError: expected `SomeOtherClass' to be a decendent of `SomeBaseClass'
    #   end
    #
    # = Dependencies
    #
    # Extensions can define one or more dependencies to be included or extended into classes that
    # include the extension. Dependencies are guaranteed to only be included or extended once.
    #
    # @example
    #   module ExtensionDependency
    #     extend Pakyow::Support::Extension
    #
    #     apply_extension do
    #       perform_some_destructive_setup
    #     end
    #
    #     ...
    #   end
    #
    #   module SomeExtension
    #     extend Pakyow::Support::Extension
    #
    #     include_dependency ExtensionDependency
    #
    #     ...
    #   end
    #
    #   class SomeClass
    #     # Causes `perform_some_destructive_setup` to be called.
    #     #
    #     include ExtensionDependency
    #
    #     # Because `ExtensionDependency` is already included into this class, the
    #     # `perform_some_destructive_setup` method will not be called again.
    #     #
    #     include SomeExtension
    #   end
    #
    module Extension
      # Restrict the extension to a particular object type.
      #
      def restrict_extension(type)
        @__extension_restriction = type
      end

      # Register a dependency to be included into classes that include the extension. If the
      # dependency is already present, it will not be included a second time.
      #
      def include_dependency(dependency)
        extension_dependencies << {
          method: :include, object: dependency
        }
      end

      # Register a dependency to be extended into classes that include the extension. If the
      # dependency is already present, it will not be extended a second time.
      #
      def extend_dependency(dependency)
        extension_dependencies << {
          method: :extend, object: dependency
        }
      end

      # Register a block to be evaluated on the including object.
      #
      def apply_extension(&block)
        @__extension_block = block
      end

      # Register a block defining class methods to be loaded into the including object.
      #
      def class_methods(&block)
        @__extension_extend_module = Module.new(&block)
      end

      # Register a block defining methods to be prepended to the including object.
      #
      def prepend_methods(&block)
        @__extension_prepend_module = Module.new(&block)
      end

      # Register a block defining methods to be loaded into the including object and its class.
      #
      def common_methods(&block)
        @__extension_common_module = Module.new(&block)
      end

      # @api private
      def included(base)
        enforce_restrictions(base)
        mixin_extension_dependencies(base)
        mixin_extension_modules(base)
        include_extensions(base)

        super
      end

      # @api private
      INHERITED_IVARS = [
        :@__extension_block,
        :@__extension_extend_module,
        :@__extension_prepend_module,
        :@__extension_common_module,
        :@__extension_dependencies
      ].freeze

      # @api private
      def inherit_extension(object)
        INHERITED_IVARS.each do |ivar|
          if object.instance_variable_defined?(ivar)
            instance_variable_set(ivar, object.instance_variable_get(ivar))
          end
        end
      end

      private

      def enforce_restrictions(base)
        if instance_variable_defined?(:@__extension_restriction) && !base.ancestors.include?(@__extension_restriction)
          raise RuntimeError, "expected `#{base}' to be a decendent of `#{@__extension_restriction}'"
        end
      end

      def mixin_extension_modules(base)
        if instance_variable_defined?(:@__extension_extend_module)
          base.extend @__extension_extend_module
        end

        if instance_variable_defined?(:@__extension_prepend_module)
          base.prepend @__extension_prepend_module
        end

        if instance_variable_defined?(:@__extension_common_module)
          base.extend @__extension_common_module
          base.include @__extension_common_module
        end
      end

      def include_extensions(base)
        if instance_variable_defined?(:@__extension_block)
          base.instance_exec(&@__extension_block)
        end
      end

      def extension_dependencies
        @__extension_dependencies ||= []
      end

      def mixin_extension_dependencies(base)
        extension_dependencies.each do |dependency|
          case dependency[:method]
          when :include
            unless base.ancestors.include?(dependency[:object])
              base.include(dependency[:object])
            end
          when :extend
            unless base.singleton_class.ancestors.include?(dependency[:object])
              base.extend(dependency[:object])
            end
          end
        end
      end
    end
  end
end
