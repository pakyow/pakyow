# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        module PlaceInMode
          extend Support::Extension

          apply_extension do
            build do |view, modes:|
              unless Pakyow.env?(:prototype)
                PlaceInMode.perform(view, modes)
              end
            end

            attach do |presenter|
              if Pakyow.env?(:prototype)
                presenter.render node: -> {
                  object.find_significant_nodes(:mode, descend: true).map { |node|
                    View.from_object(node)
                  }
                } do
                  PlaceInMode.perform(view, __modes)
                end
              end
            end

            expose do |connection|
              if Pakyow.env?(:prototype)
                connection.set(:__modes, connection.params[:modes] || [:default])
              end
            end
          end

          # @api private
          def self.perform(view, modes)
            if modes.length == 1 && modes.first.to_sym == :default
              modes = view.info(:modes) || modes
            end

            modes.map!(&:to_sym)

            if view.object.is_a?(StringDoc::Node) && view.object.significant?(:mode) && !modes.include?(view.object.label(:mode))
              view.remove
            else
              view.object.each_significant_node(:mode, descend: true).select { |node|
                !modes.include?(node.label(:mode))
              }.each(&:remove)
            end
          end
        end
      end
    end
  end
end
