# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/controller"
require "pakyow/routing/extensions"
require "pakyow/routing/helpers/exposures"

require "pakyow/application/actions/routing/respond_missing"
require "pakyow/application/behavior/routing/definition"

require "pakyow/security/config"
require "pakyow/security/behavior/disabling"
require "pakyow/security/behavior/helpers"
require "pakyow/security/behavior/insecure"
require "pakyow/security/behavior/pipeline"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:routing)
      def boot
        object.class_eval do
          include Pakyow::Application::Behavior::Routing::Definition

          isolate Controller do
            include Extension::Resource
          end

          # Make controllers definable on the app.
          #
          stateful :controller, isolated(:Controller)

          # Load controllers for the app.
          #
          aspect :controllers

          # Load resources for the app.
          #
          aspect :resources

          register_helper :active, Helpers::Exposures

          # Include helpers into the controller class.
          #
          on "load" do
            self.class.include_helpers :active, isolated(:Controller)
          end

          # Create the global controller instance.
          #
          after "initialize" do
            @global_controller = isolated(:Controller).new(self)
          end

          # Register routes as endpoints.
          #
          after "initialize" do
            unless Pakyow.env?(:prototype)
              state(:controller).each do |controller|
                controller.build_endpoints(endpoints)
              end
            end
          end

          # Register controllers as pipeline actions.
          #
          after "initialize" do
            unless Pakyow.env?(:prototype)
              state(:controller).each do |controller|
                action(controller, self)
              end
            end
          end

          # Register the respond missing action as the last registered action.
          #
          after "initialize", priority: -10 do
            unless Pakyow.env?(:prototype) || is_a?(Plugin)
              action(Application::Actions::Routing::RespondMissing)
            end
          end

          # Expose the global controller for handling errors from other frameworks.
          #
          def controller_for_connection(connection)
            @global_controller.dup.tap do |controller|
              controller.instance_variable_set(:@connection, connection)
            end
          end

          require "pakyow/support/message_verifier"
          handle Support::MessageVerifier::TamperedMessage, as: :forbidden

          include Security::Config
          include Security::Behavior::Disabling
          include Security::Behavior::Helpers
          include Security::Behavior::Insecure
          include Security::Behavior::Pipeline
        end
      end
    end
  end
end
