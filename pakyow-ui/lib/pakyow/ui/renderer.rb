# frozen_string_literal: true

require "pakyow/presenter/renderer"

module Pakyow
  module UI
    class Renderer < Pakyow::Presenter::Renderer
      def find_presenter(*)
        presenter_class = super || Pakyow::Presenter::ViewPresenter
        @connection.app.ui_presenters.find { |ui_presenter|
          ui_presenter.ancestors.include?(presenter_class)
        }
      end
    end
  end
end
