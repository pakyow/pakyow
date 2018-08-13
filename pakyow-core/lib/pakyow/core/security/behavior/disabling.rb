# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Security
    module Behavior
      module Disabling
        extend Support::Extension

        apply_extension do
          subclass :Controller do
            def self.disable_protection(type, only: [], except: [])
              if type.to_sym == :csrf
                if only.any? || except.any?
                  Pipelines::CSRF.__pipeline.actions.each do |action|
                    if only.any?
                      skip_action action.target, only: only
                    end

                    if except.any?
                      action action.target, only: except
                    end
                  end
                else
                  exclude_pipeline Pipelines::CSRF
                end
              else
                raise ArgumentError, "Unknown protection type `#{type}'"
              end
            end
          end
        end
      end
    end
  end
end
