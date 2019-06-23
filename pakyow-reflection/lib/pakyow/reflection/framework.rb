# frozen_string_literal: true

require "pakyow/framework"
require "pakyow/support/inflector"

require "pakyow/reflection/behavior/config"
require "pakyow/reflection/behavior/reflecting"
require "pakyow/reflection/behavior/rendering/install_form_metadata"
require "pakyow/reflection/mirror"

module Pakyow
  module Reflection
    class Framework < Pakyow::Framework(:reflection)
      def boot
        object.include Behavior::Config
        object.include Behavior::Reflecting

        object.isolated :Renderer do
          include Behavior::Rendering::InstallFormMetadata
        end

        object.after "load" do
          operation :reflect do
            action :verify do
              if (reflected_action = controller.connection.get(:__reflected_action)) && reflected_action.name == controller.connection.get(:__endpoint_name)
                case reflected_action.name
                when :create, :update
                  controller.verify_submitted_form
                end
              end
            end

            action :perform do
              if (reflected_action = controller.connection.get(:__reflected_action)) && reflected_action.name == controller.connection.get(:__endpoint_name)
                case reflected_action.name
                when :create
                  controller.reflective_create
                when :update
                  controller.reflective_update
                when :delete
                  controller.reflective_delete
                end
              end
            end

            action :expose do
              if controller.connection.set?(:__reflected_endpoints)
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
