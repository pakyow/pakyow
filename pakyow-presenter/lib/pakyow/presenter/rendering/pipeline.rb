# frozen_string_literal: true

require "pakyow/support/pipeline"

require "pakyow/presenter/rendering/actions/insert_prototype_bar"
require "pakyow/presenter/rendering/actions/install_authenticity"
require "pakyow/presenter/rendering/actions/install_endpoints"
require "pakyow/presenter/rendering/actions/place_in_mode"
require "pakyow/presenter/rendering/actions/render_components"
require "pakyow/presenter/rendering/actions/setup_forms"

module Pakyow
  module Presenter
    module Rendering
      module Pipeline
        extend Support::Pipeline

        action :install_authenticity, Actions::InstallAuthenticity
        action :install_endpoints, Actions::InstallEndpoints
        action :insert_prototype_bar, Actions::InsertPrototypeBar
        action :place_in_mode, Actions::PlaceInMode
        action :render_components, Actions::RenderComponents
        action :dispatch
        action :setup_forms, Actions::SetupForms
      end
    end
  end
end
