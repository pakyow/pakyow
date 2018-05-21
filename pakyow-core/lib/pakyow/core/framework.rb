# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/core/controller"
require "pakyow/core/route"
require "pakyow/core/route"
require "pakyow/core/expansion"
require "pakyow/core/extensions"

module Pakyow
  module Routing
    # @api private
    class RespondMissing
      def initialize(app)
        @app = app
      end

      def call(connection)
        @app.class.const_get(:Controller).new(connection).trigger(404)
      end
    end

    # Defines a RESTful resource.
    #
    # @see Routing::Extension::Resource
    #
    def resources(name, path, *args, param: Pakyow::Routing::Extension::Resource::DEFAULT_PARAM, &block)
      controller name, path, *args do
        expand_within(:resources, param: param, &block)
      end
    end

    # Registers an error handler automatically available in all Controller instances.
    #
    # @see Routing::Behavior::ErrorHandling#handle
    def handle(name_exception_or_code, as: nil, &block)
      const_get(:Controller).handle(name_exception_or_code, as: as, &block)
    end

    # Extends an existing controller.
    #
    # @example
    #   controller :admin, "/admin" do
    #     before :require_admin
    #
    #     def require_admin
    #       ...
    #     end
    #   end
    #
    #   extend_controller :admin do
    #     resources :posts, "/posts" do
    #       ...
    #     end
    #   end
    #
    def extend_controller(controller_name)
      if controller_name.is_a?(Support::ClassName)
        controller_name = controller_name.name
      end

      matched_controller = @state[:controller].instances.find { |controller|
        controller.__class_name.name == controller_name
      }

      if matched_controller
        matched_controller.instance_exec(&Proc.new)
      else
        fail "could not find controller named `#{controller_name}'"
      end
    end

    class Framework < Pakyow::Framework(:core)
      def boot
        controller_class = subclass(Controller) {
          include Pakyow::Routing::Extension::Resource
        }

        app.class_eval do
          extend Routing

          # Make it possible to define controllers on the app.
          stateful :controller, controller_class

          # Load defined controllers into the namespace.
          aspect :controllers

          helper Pakyow::Routing::Helpers
          helper Pakyow::Routing::Helpers::CSRF

          settings_for :csrf do
            setting :origin_whitelist, []
            setting :allow_empty_referrer, true
            setting :protection, {}
            setting :param, :authenticity_token
          end

          require "pakyow/core/security/csrf/verify_same_origin"
          require "pakyow/core/security/csrf/verify_authenticity_token"

          config.csrf.protection = {
            origin: Security::CSRF::VerifySameOrigin.new(
              origin_whitelist: config.csrf.origin_whitelist,
              allow_empty_referrer: config.csrf.allow_empty_referrer
            ),

            authenticity: Security::CSRF::VerifyAuthenticityToken.new({}),
          }

          require "pakyow/core/security/csrf/pipeline"
          controller_class.include_pipeline Security::CSRF

          handle InsecureRequest, as: 403 do
            trigger(403)
          end

          controller_class.class_eval do
            def self.disable_protection(type, only: [], except: [])
              if type.to_sym == :csrf
                if only.any? || except.any?
                  Security::CSRF.__pipeline.actions.each do |action|
                    if only.any?
                      skip_action action.target, only: only
                    end

                    if except.any?
                      action action.target, only: except
                    end
                  end
                else
                  exclude_pipeline Security::CSRF
                end
              else
                raise ArgumentError, "Unknown protection type `#{type}'"
              end
            end
          end

          before :load do
            # Include other registered helpers into the controller class.
            config.helpers.each do |helper|
              controller_class.include helper
            end
          end
        end
      end
    end
  end

  class App
    # @!parse include Routing
  end
end
