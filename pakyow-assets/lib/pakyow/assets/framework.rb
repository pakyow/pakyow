# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/assets/asset"
require "pakyow/assets/pack"

require "pakyow/assets/actions/process"
require "pakyow/assets/actions/public"

require "pakyow/assets/types/es6"
require "pakyow/assets/types/sass"
require "pakyow/assets/types/scss"

require "pakyow/assets/behavior/config"
require "pakyow/assets/behavior/assets"
require "pakyow/assets/behavior/packs"
require "pakyow/assets/behavior/rendering"
require "pakyow/assets/behavior/views"
require "pakyow/assets/behavior/silencing"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        register_tasks

        app.class_eval do
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

          after :load do
            config.assets.extensions.each do |extension|
              config.process.watched_paths << File.join(config.presenter.path, "**/*#{extension}")
            end
          end

          after :configure do
            if !config.assets.process && self.class.includes_framework?(:presenter)
              self.class.processor :html do |content|
                state_for(:asset).each do |asset|
                  content.gsub!(asset.logical_path, asset.public_path)
                end

                content
              end
            end
          end

          if const_defined?(:Renderer)
            const_get(:Renderer).class_eval do
              include Behavior::Rendering
            end
          end
        end
      end

      private

      def register_tasks
        Pakyow.config.tasks.paths << File.expand_path("../tasks", __FILE__)
      end
    end
  end
end
