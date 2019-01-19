# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/controller"
require "pakyow/routing/extensions"
require "pakyow/routing/helpers/exposures"

require "pakyow/behavior/definition"

require "pakyow/security/behavior/config"
require "pakyow/security/behavior/disabling"
require "pakyow/security/behavior/helpers"
require "pakyow/security/behavior/insecure"
require "pakyow/security/behavior/pipeline"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:routing)
      def boot
        object.class_eval do
          include Pakyow::Behavior::Definition

          isolate Controller do
            include Extension::Resource
          end

          # Make controllers definable on the app.
          #
          stateful :controller, isolated(:Controller) do |args, _opts|
            if self.ancestors.include?(Plugin)
              # When using plugins, prefix controller paths with the mount path.
              #
              name, matcher = Controller.send(:parse_name_and_matcher_from_args, *args)
              path = File.join(@mount_path, Controller.send(:path_from_matcher, matcher).to_s)
              args.replace([name, path])
            end
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
          before :load do
            self.class.include_helpers :active, isolated(:Controller)
          end

          # Create a global controller instance used to handle errors from other
          # parts of the framework.
          #
          after :initialize do
            @global_controller = isolated(:Controller).new(self)
          end

          require "pakyow/support/message_verifier"
          handle Support::MessageVerifier::TamperedMessage, as: :forbidden

          # @api private
          def controller_for_connection(connection)
            @global_controller.dup.tap do |controller|
              controller.instance_variable_set(:@connection, connection)
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
