# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/ui/recordable"

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
          after "initialize" do
            @ui_presenters = [isolated(:Presenter)].concat(
              state(:presenter)
            ).concat(
              state(:component).map(&:__presenter_class)
            ).map { |presenter_class|
              Class.new(presenter_class) do
                include Recordable
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
