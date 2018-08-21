# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module UI
    module Wrappable
      extend Support::Extension

      def find_presenter(*)
        presenter_class = super || Presenter::Presenter
        @connection.app.ui_presenters.find { |ui_presenter|
          ui_presenter.ancestors.include?(presenter_class)
        }
      end
    end
  end
end
