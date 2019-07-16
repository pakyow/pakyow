# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/ui/recordable"

module Pakyow
  class Application
    module Behavior
      module UI
        module Recording
          extend Support::Extension

          # @api private
          def find_ui_presenter_for(presenter_class)
            if is_a?(Plugin)
              # Look for the presenter in the plugin first, falling back to the app.
              #
              ui_presenter_class = parent.ui_presenters.find { |klass|
                klass.ancestors.include?(presenter_class)
              }
            end

            ui_presenter_class ||= @ui_presenters.find { |klass|
              klass.ancestors.include?(presenter_class)
            }
          end

          apply_extension do
            # Create subclasses of each presenter, then make the subclasses recordable.
            # These subclasses will be used when performing a ui presentation instead
            # of the original presenter, but they'll behave identically!
            #
            after "initialize" do
              @ui_presenters = [isolated(:Presenter)].concat(
                state(:presenter)
              ).concat(
                state(:component).map(&:__presenter_class)
              ).map { |presenter_class|
                Class.new(presenter_class) do
                  include Pakyow::UI::Recordable
                end
              }
            end

            class_eval do
              attr_reader :ui_presenters
            end
          end
        end
      end
    end
  end
end
