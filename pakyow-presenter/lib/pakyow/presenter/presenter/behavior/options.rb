# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Presenter
      module Behavior
        module Options
          extend Support::Extension

          apply_extension do
            class_state :global_options, default: {}, inheritable: true

            action :use_global_options do
              self.class.global_options.each do |form_binding, options|
                if form = form(form_binding)
                  options.each do |field_binding, metadata|
                    if field = form.find(field_binding)
                      if metadata[:block]
                        form.options_for(field_binding) do |field|
                          instance_exec(field, &metadata[:block])
                        end
                      else
                        form.options_for(field_binding, metadata[:options])
                      end
                    end
                  end
                end
              end
            end
          end

          class_methods do
            def options_for(form_binding, field_binding, options = nil, &block)
              form_binding = form_binding.to_sym
              field_binding = field_binding.to_sym

              @global_options[form_binding] ||= {}
              @global_options[form_binding][field_binding] = {
                options: options,
                block: block
              }
            end
          end
        end
      end
    end
  end
end
