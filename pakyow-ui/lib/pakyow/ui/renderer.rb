# frozen_string_literal: true

require "pakyow/presenter/renderer"

require "pakyow/ui/presenter"

module Pakyow
  module UI
    class Renderer < Pakyow::Presenter::Renderer
      def perform
        # TODO: handle implicit presentation
        # if @presenter.class == ViewPresenter
        #   find_and_present_presentables(@connection.values)
        # else
        define_presentables(@connection.values)
        @presenter.instance_exec(&@presenter.block)
        # end
      end

      def to_json(*)
        @presenter.to_json
      end
    end
  end
end
