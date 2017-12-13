# frozen_string_literal: true

module Pakyow
  module Routing
    # @api private
    module HookMerger
      def merge_hooks(hooks_to_merge, merge_into = hooks)
        %i[before after around].each do |type|
          (merge_into[type] ||= []).concat(hooks_to_merge[type] || [])
        end
      end
    end
  end
end
