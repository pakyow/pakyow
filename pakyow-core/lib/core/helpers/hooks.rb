module Pakyow
  module Helpers
    # Methods to register and call hooks before and after particular triggers.
    #
    # @api public
    module Hooks
      TYPES = %i(before after)
      TRIGGERS = %i(init load process route match error configure reload)

      # Registers a before hook for a particular trigger.
      #
      # @api public
      def before(trigger, &block)
        register_hook(:before, trigger, block)
      end

      # Registers an after hook for a particular trigger.
      #
      # @api public
      def after(trigger, &block)
        register_hook(:after, trigger, block)
      end

      # Fetches a hook by type (before | after) and trigger.
      #
      # @api private
      def hook(type, trigger)
        check_hook_type(type)
        check_trigger(trigger)

        hooks[type.to_sym][trigger.to_sym]
      end

      protected

      def hooks
        return @hooks unless @hooks.nil?

        @hooks = {
          before: {},
          after: {}
        }

        TRIGGERS.each do |name|
          @hooks[:before][name.to_sym] = []
          @hooks[:after][name.to_sym] = []
        end

        @hooks
      end

      def register_hook(type, trigger, block)
        raise ArgumentError, 'Expected a block' if block.nil?

        trigger = trigger.to_sym

        check_trigger(trigger)
        check_hook_type(type)

        hooks[type][trigger] << block
      end

      def hook_around(trigger)
        call_hooks :before, trigger
        yield
        call_hooks :after, trigger
      end

      def call_hooks(type, trigger)
        hook(type, trigger).each do |block|
          instance_exec(&block)
        end
      end

      def check_trigger(trigger)
        return true if TRIGGERS.include?(trigger)
        raise ArgumentError, "Hook trigger #{trigger} doesn't exist"
      end

      def check_hook_type(type)
        return true if TYPES.include?(type)
        raise ArgumentError, "Hook type #{type} doesn't exist"
      end
    end
  end
end
