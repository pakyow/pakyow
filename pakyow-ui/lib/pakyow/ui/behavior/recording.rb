# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/ui/recordable"
require "pakyow/ui/wrappable"

module Pakyow
  module UI
    module Behavior
      module Recording
        extend Support::Extension

        apply_extension do
          # Create subclasses of each presenter, then make the subclasses recordable.
          # These subclasses will be used when performing a ui presentation instead
          # of the original presenter, but they'll behave identically!
          #
          after :initialize do
            @ui_presenters = [Presenter::Presenter].concat(
              state(:presenter)
            ).concat(
              state(:component).map(&:__presenter_class)
            ).map { |presenter_class|
              Class.new(presenter_class) do
                include Recordable
              end
            }
          end

          # Subclass each renderer to use the recordable presenters.
          #
          after :initialize do
            @ui_renderers = []

            @ui_renderers << Class.new(isolated(:ComponentRenderer)) do
              include Wrappable

              pipeline :ui do
                action :install_endpoints, Presenter::Actions::InstallEndpoints
                action :cleanup_prototype_nodes, Presenter::Actions::CleanupPrototypeNodes
                action :dispatch
              end

              use_pipeline :ui
            end

            @ui_renderers << Class.new(isolated(:ViewRenderer)) do
              include Wrappable

              pipeline :ui do
                action :install_endpoints, Presenter::Actions::InstallEndpoints
                action :cleanup_prototype_nodes, Presenter::Actions::CleanupPrototypeNodes
                action :place_in_mode, Presenter::Actions::PlaceInMode
                action :dispatch
              end

              use_pipeline :ui
            end
          end

          class_eval do
            attr_reader :ui_presenters
            attr_reader :ui_renderers
          end
        end
      end
    end
  end
end
