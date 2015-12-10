module Pakyow
  module Helpers
    # Methods to register and call hooks before and after particular triggers.
    #
    # @api public
    module Hooks
      TRIGGERS = %i(init load process route match error configure)

      # Registers a before hook for a particular trigger.
      #
      # @api public
      def before(trigger, &block)
        hooks[:before][trigger.to_sym] << block
      end

      # Registers an after hook for a particular trigger.
      #
      # @api public
      def after(trigger, &block)
        hooks[:after][trigger.to_sym] << block
      end

      # Fetches a hook by type (before | after) and trigger.
      #
      # @api private
      def hook(type, trigger)
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
    end
  end
end
