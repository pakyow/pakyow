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
      end
    end
  end
end
