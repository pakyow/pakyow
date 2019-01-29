# frozen_string_literal: true

require "pakyow/framework"
require "pakyow/support/inflector"

require "pakyow/reflection/behavior/config"
require "pakyow/reflection/behavior/reflecting"
require "pakyow/reflection/mirror"

module Pakyow
  module Reflection
    class Framework < Pakyow::Framework(:reflection)
      def boot
        object.include Behavior::Config
        object.include Behavior::Reflecting

        object.isolated :ViewRenderer do
          action :set_reflection_framework_metadata, before: :setup_form_objects do
            presenter.forms.each do |form|
              form.view.label(:metadata)[:view_path] = templates_path
            end
          end
        end
      end
    end
  end
end
