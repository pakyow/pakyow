# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/assets/asset"
require "pakyow/assets/pack"

require "pakyow/assets/behavior/config"
require "pakyow/assets/behavior/assets"
require "pakyow/assets/behavior/packs"
require "pakyow/assets/behavior/rendering"
require "pakyow/assets/behavior/building"
require "pakyow/assets/behavior/views"
require "pakyow/assets/behavior/silencing"
require "pakyow/assets/behavior/externals"
require "pakyow/assets/behavior/watching"
require "pakyow/assets/behavior/prelaunching"
require "pakyow/assets/behavior/processing"

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

          include Behavior::Config
          include Behavior::Assets
          include Behavior::Packs
          include Behavior::Views
          include Behavior::Silencing
          include Behavior::Externals
          include Behavior::Watching
          include Behavior::Prelaunching
          include Behavior::Processing
          include Behavior::Building
        end
      end
    end
  end
end
