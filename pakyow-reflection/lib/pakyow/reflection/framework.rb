# frozen_string_literal: true

require "pakyow/framework"
require "pakyow/support/inflector"

require "pakyow/application/config/reflection"
require "pakyow/application/behavior/reflection/reflecting"
require "pakyow/presenter/renderer/behavior/reflection/install_form_metadata"
require "pakyow/reflection/mirror"

module Pakyow
  module Reflection
    class Framework < Pakyow::Framework(:reflection)
      def boot
        object.include Application::Config::Reflection
        object.include Application::Behavior::Reflection::Reflecting

        object.isolated :Renderer do
          include Presenter::Renderer::Behavior::Reflection::InstallFormMetadata
        end

        object.isolated :Controller do
          def reflect(&block)
            operations.reflect(controller: self, &block)
          end
        end

        object.after "load" do
          operation :reflect do
            action :verify do
              if (reflected_action = controller.connection.get(:__reflected_action)) && reflected_action.name == controller.connection.get(:__endpoint_name)
                case reflected_action.name
                when :create, :update
                  controller.verify_reflected_form
                end
              end
            end

            action :perform do
              if (reflected_action = controller.connection.get(:__reflected_action)) && reflected_action.name == controller.connection.get(:__endpoint_name)
                case reflected_action.name
                when :create, :update, :delete
                  controller.perform_reflected_action
                  @object = controller.instance_variable_get(:@object)
                end
              end
            end

            action :expose do
              if controller.connection.set?(:__reflected_endpoint)
                controller.reflective_expose
              end
            end

            action :redirect do
              if (reflected_action = controller.connection.get(:__reflected_action)) && reflected_action.name == controller.connection.get(:__endpoint_name)
                unless controller.connection.halted?
                  controller.redirect_to_reflected_destination
                end
              end
            end
          end
        end
      end
    end
  end
end
