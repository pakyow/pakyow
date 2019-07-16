# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/controller"
require "pakyow/routing/extensions"
require "pakyow/routing/helpers/exposures"

require "pakyow/behavior/definition"

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
          on "load" do
            self.class.include_helpers :active, isolated(:Controller)
          end

          # Create the global controller instance.
          #
          after "initialize" do
            @global_controller = isolated(:Controller).new(self)
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
