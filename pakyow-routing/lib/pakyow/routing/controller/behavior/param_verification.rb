# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/errors"

require "pakyow/behavior/verification"

module Pakyow
  module Routing
    module Behavior
      module ParamVerification
        extend Support::Extension

        apply_extension do
          class_state :__allowed_params, default: [], inheritable: true

          include Pakyow::Behavior::Verification

          # Define the data we wish to verify.
          #
          verifies :params

          # Handle all invalid data errors as a bad request, by default.
          #
          handle InvalidData, as: :bad_request
        end

        class_methods do
          # Perform input verification before one or more routes, identified by name.
          #
          # @see Pakyow::Verifier
          #
          # @api public
          def verify(*names, &block)
            verification_method_name = :"verify_#{names.join("_")}"

            define_method verification_method_name do
              local_allowed_params = self.class.__allowed_params

              verify do
                local_allowed_params.each do |allowed_param|
                  optional allowed_param
                end

                instance_exec(&block)
              end
            end

            action verification_method_name, only: names
          end

          # Set one or more params as optional in all routes.
          #
          def allow_params(*names)
            @__allowed_params.concat(names).uniq!
          end
        end

        prepend_methods do
          def verify(values = nil, &block)
            local_allowed_params = self.class.__allowed_params

            super do
              local_allowed_params.each do |allowed_param|
                optional allowed_param
              end

              instance_exec(&block)
            end
          end
        end
      end
    end
  end
end
