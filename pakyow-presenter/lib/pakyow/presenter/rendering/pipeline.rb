# frozen_string_literal: true

require "pakyow/support/pipeline"

require "pakyow/presenter/rendering/actions/render_components"

module Pakyow
  module Presenter
    module Rendering
      module Pipeline
        extend Support::Pipeline

        action :render_components, Actions::RenderComponents
        action :dispatch
      end
    end
  end
end
