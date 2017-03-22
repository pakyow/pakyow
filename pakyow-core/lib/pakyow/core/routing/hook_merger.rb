module Pakyow
  module Routing
    # @api private
    module HookMerger
      def merge_hooks(hooks_to_merge)
        hooks.each_pair do |type, hooks_of_type|
          hooks_of_type.concat(hooks_to_merge[type] || [])
        end
      end
    end
  end
end
