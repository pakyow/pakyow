# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/application/behavior/assets"
require "pakyow/application/behavior/assets/packs"
require "pakyow/application/behavior/assets/silencing"
require "pakyow/application/behavior/assets/externals"
require "pakyow/application/behavior/assets/watching"
require "pakyow/application/behavior/assets/prelaunching"
require "pakyow/application/behavior/assets/processing"
require "pakyow/application/behavior/assets/types"

require "pakyow/application/config/assets"

require "pakyow/presenter/renderer/behavior/assets/install_assets"

require "pakyow/assets/asset"
require "pakyow/assets/pack"

require "pakyow/application/actions/assets/process"
require "pakyow/application/actions/assets/public"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        object.class_eval do
          definable :asset_type, Asset

          # Let other frameworks load their own assets.
          #
          definable :asset, Asset

          # Let other frameworks load their own asset packs.
          #
          definable :pack, Pack

          include Application::Config::Assets
          include Application::Behavior::Assets
          include Application::Behavior::Assets::Packs
          include Application::Behavior::Assets::Silencing
          include Application::Behavior::Assets::Externals
          include Application::Behavior::Assets::Watching
          include Application::Behavior::Assets::Prelaunching
          include Application::Behavior::Assets::Processing
          include Application::Behavior::Assets::Types

          after "initialize" do
            action Application::Actions::Assets::Public, self
            action Application::Actions::Assets::Process
          end

          after "load" do
            isolated(:Renderer) do
              # Load this one later, in case other actions define components that will load assets.
              #
              include Presenter::Renderer::Behavior::Assets::InstallAssets
            end
          end
        end
      end
    end
  end
end
