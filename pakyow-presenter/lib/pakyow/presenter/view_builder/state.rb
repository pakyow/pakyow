# frozen_string_literal: true

require "pakyow/support/pipeline"

module Pakyow
  module Presenter
    class ViewBuilder
      class State
        include Pakyow::Support::Pipeline::Object

        attr_reader :app, :view, :path

        def initialize(app:, view:, path:)
          @app, @view, @path = app, view, path
        end
      end
    end
  end
end
