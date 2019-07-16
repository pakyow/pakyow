# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/app/behavior/assets"
require "pakyow/app/behavior/assets/packs"
require "pakyow/app/behavior/assets/silencing"
require "pakyow/app/behavior/assets/externals"
require "pakyow/app/behavior/assets/watching"
require "pakyow/app/behavior/assets/prelaunching"
require "pakyow/app/behavior/assets/processing"
require "pakyow/app/config/assets"

require "pakyow/presenter/renderer/behavior/assets/install_assets"

require "pakyow/assets/asset"
require "pakyow/assets/pack"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        object.class_eval do
          # Let other frameworks load their own assets.
          #
          stateful :asset, Asset

          # Let other frameworks load their own asset packs.
          #
          stateful :pack, Pack

          include App::Config::Assets
          include App::Behavior::Assets
          include App::Behavior::Assets::Packs
          include App::Behavior::Assets::Silencing
          include App::Behavior::Assets::Externals
          include App::Behavior::Assets::Watching
          include App::Behavior::Assets::Prelaunching
          include App::Behavior::Assets::Processing

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
