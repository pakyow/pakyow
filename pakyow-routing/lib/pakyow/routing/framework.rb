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
      using Support::Refinements::String::Normalization

      def boot
        object.class_eval do
          include Pakyow::Application::Behavior::Routing::Definition

          # Make controllers definable on the app.
          #
          definable :controller, Controller, builder: -> (*args, **kwargs) {
            controller_name, matcher = Controller.parse_name_and_matcher_from_args(*args)

            path = if matcher.is_a?(String)
              matcher
            else
              nil
            end

            matcher ||= "/"

            matcher = if matcher.is_a?(String)
              converted_matcher = String.normalize_path(matcher.split("/").map { |segment|
                if segment.include?(":")
                  "(?<#{segment[1..-1]}>(\\w|[-.~:@!$\\'\\(\\)\\*\\+,;])+)"
                else
                  segment
                end
              }.join("/"))

              Regexp.new("^#{String.normalize_path(converted_matcher)}")
            else
              matcher
            end

            return controller_name, path: path, matcher: matcher, **kwargs
          } do
            include Extension::Resource
          end

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

          # Register controllers as pipeline actions.
          #
          after "initialize" do
            unless Pakyow.env?(:prototype)
              controllers.each do |controller|
                action(controller, self)
              end
            end
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
              controllers.each do |controller|
                controller.build_endpoints(endpoints)
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
