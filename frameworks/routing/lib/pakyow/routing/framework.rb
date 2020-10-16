# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:routing)
      using Support::Refinements::String::Normalization

      def boot
        require "pakyow/validations"

        require_relative "controller"
        require_relative "extensions"
        require_relative "helpers/exposures"

        require_relative "../application/behavior/routing/definition"

        require_relative "../security/behavior/disabling"
        require_relative "../security/behavior/helpers"
        require_relative "../security/behavior/insecure"
        require_relative "../security/behavior/pipeline"

        object.class_eval do
          include Pakyow::Application::Behavior::Routing::Definition

          # Make controllers definable on the app.
          #
          definable :controller, Controller, builder: ->(*namespace, object_name, **opts) {
            controller_name, matcher = Controller.parse_name_and_matcher_from_args(*namespace, object_name)

            path = if matcher.is_a?(String)
              matcher
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

            opts[:path] = path
            opts[:matcher] = matcher

            return [], controller_name, opts
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
          after "load" do
            include_helpers :active, isolated(:Controller)
          end

          # Register controllers as pipeline actions.
          #
          after "setup" do
            unless Pakyow.env?(:prototype)
              controllers.each do |controller|
                action(controller.new(self))
              end
            end
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

          require "pakyow/support/message_verifier"
          handle Support::MessageVerifier::TamperedMessage, as: :forbidden

          include Security::Behavior::Disabling
          include Security::Behavior::Helpers
          include Security::Behavior::Insecure
          include Security::Behavior::Pipeline

          configurable :security do
            configurable :csrf do
              setting :protection, {}
              setting :origin_whitelist, []
              setting :param, :"pw-authenticity-token"
            end
          end

          require "pakyow/security/csrf/verify_same_origin"
          require "pakyow/security/csrf/verify_authenticity_token"

          config.security.csrf.protection = {
            origin: Security::CSRF::VerifySameOrigin.new(
              origin_whitelist: config.security.csrf.origin_whitelist
            ),

            authenticity: Security::CSRF::VerifyAuthenticityToken.new({})
          }
        end
      end
    end
  end
end
