# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        module Reflection
          module InstallFormMetadata
            extend Support::Extension

            apply_extension do
              build do |view, composer:|
                forms = view.forms
                if !view.object.is_a?(StringDoc) && view.object.significant?(:form)
                  forms << view
                end

                forms.each do |form|
                  form.label(:form)[:view_path] = composer.view_path
                end
              end
            end
          end
        end
      end
    end
  end
end
