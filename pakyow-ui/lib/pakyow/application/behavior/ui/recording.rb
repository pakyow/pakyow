# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../../ui/recordable"

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
              ui_presenter_class = parent.class.ui_presenters.find { |klass|
                klass.ancestors.include?(presenter_class)
              }
            end

            ui_presenter_class ||= self.class.ui_presenters.find { |klass|
              klass.ancestors.include?(presenter_class)
            }
          end

          class_methods do
            attr_reader :ui_presenters
          end

          apply_extension do
            # Create subclasses of each presenter, then make the subclasses recordable.
            # These subclasses will be used when performing a ui presentation instead
            # of the original presenter, but they'll behave identically!
            #
            before "setup.presenter.renders" do
              @ui_presenters = [isolated(:Presenter)].concat(
                presenters.each.to_a
              ).concat(
                components.each.map(&:__presenter_class)
              ).map { |presenter_class|
                Class.new(presenter_class) do
                  include Pakyow::UI::Recordable
                end
              }
            end
          end
        end
      end
    end
  end
end
