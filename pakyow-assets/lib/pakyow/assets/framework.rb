# frozen_string_literal: true

require "pakyow/assets/asset"

require "pakyow/assets/actions/process"
require "pakyow/assets/actions/public"

require "pakyow/assets/types/es6"
require "pakyow/assets/types/sass"
require "pakyow/assets/types/scss"

require "pakyow/assets/behavior/config"
require "pakyow/assets/behavior/assets"
require "pakyow/assets/behavior/packs"
require "pakyow/assets/behavior/packs"
require "pakyow/assets/behavior/views"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        register_tasks

        app.class_eval do
          # Makes it possible for other frameworks to load their own assets.
          #
          stateful :asset, Asset

          include Behavior::Config
          include Behavior::Assets
          include Behavior::Packs
          include Behavior::Views
        end
      end

      private

      def register_tasks
        Pakyow.config.tasks.paths << File.expand_path("../tasks", __FILE__)
      end
    end
  end
end
