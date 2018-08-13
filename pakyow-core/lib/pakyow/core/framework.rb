# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/core/controller"
require "pakyow/core/extensions"

require "pakyow/core/helpers/definition"
require "pakyow/core/helpers/exposures"

require "pakyow/core/security/behavior/config"
require "pakyow/core/security/behavior/disabling"
require "pakyow/core/security/behavior/helpers"
require "pakyow/core/security/behavior/insecure"
require "pakyow/core/security/behavior/pipeline"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:core)
      def boot
        app.class_eval do
          subclass! Controller do
            include Extension::Resource
            include Helpers::Exposures
          end

          extend Helpers::Definition

          # Make controllers definable on the app.
          #
          stateful :controller, subclass(:Controller)

          # Load controllers for the app.
          #
          aspect :controllers

          # Include helpers into the controller class.
          #
          before :load do
            config.helpers.each do |helper|
              subclass(:Controller).include helper
            end
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
