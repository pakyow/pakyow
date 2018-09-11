# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/controller"
require "pakyow/routing/extensions"
require "pakyow/routing/helpers/exposures"

require "pakyow/app/behavior/definition"

require "pakyow/security/behavior/config"
require "pakyow/security/behavior/disabling"
require "pakyow/security/behavior/helpers"
require "pakyow/security/behavior/insecure"
require "pakyow/security/behavior/pipeline"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:routing)
      def boot
        app.class_eval do
          include App::Behavior::Definition

          isolate Controller do
            include Extension::Resource
          end

          # Make controllers definable on the app.
          #
          stateful :controller, isolated(:Controller)

          # Load controllers for the app.
          #
          aspect :controllers

          helper :active, Helpers::Exposures

          # Include helpers into the controller class.
          #
          before :load do
            self.class.include_helpers :active, isolated(:Controller)
          end

          include Security::Behavior::Config
          include Security::Behavior::Disabling
          include Security::Behavior::Helpers
          include Security::Behavior::Insecure
          include Security::Behavior::Pipeline
        end
      end
    end
  end
end
