# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module PlaceInMode
        extend Support::Extension

        apply_extension do
          build do |view, app:, mode:|
            unless Pakyow.env?(:prototype)
              PlaceInMode.perform(view, mode)
            end
          end

          attach do |presenter|
            if Pakyow.env?(:prototype)
              presenter.render node: -> {
                object.find_significant_nodes(:mode).map { |node|
                  View.from_object(node)
                }
              } do
                PlaceInMode.perform(view, __mode)
              end
            end
          end

          expose do |connection|
            if Pakyow.env?(:prototype)
              connection.set(:__mode, connection.params[:mode])
            end
          end
        end

        # @api private
        def self.perform(view, mode)
          return unless mode

          if mode == :default
            mode = view.info(:mode) || mode
          end

          mode = mode.to_sym
          view.object.each_significant_node(:mode).select { |node|
            node.label(:mode) != mode
          }.each(&:remove)
        end
      end
    end
  end
end
