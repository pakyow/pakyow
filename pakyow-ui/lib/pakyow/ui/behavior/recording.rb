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
            ).map { |presenter_class|
              Class.new(presenter_class).tap do |subclass|
                subclass.include Recordable
              end
            }
          end

          # Subclass each renderer to use the recordable presenters.
          #
          after :initialize do
            @ui_renderers = [subclass(:Renderer)].map { |renderer_class|
              Class.new(renderer_class).tap do |subclass|
                subclass.include Wrappable
              end
            }
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
