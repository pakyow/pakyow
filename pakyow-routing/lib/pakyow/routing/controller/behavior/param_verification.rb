# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/errors"
require "pakyow/verification"

module Pakyow
  module Routing
    module Behavior
      module ParamVerification
        extend Support::Extension

        apply_extension do
          include Verification

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
              verify(&block)
            end

            action verification_method_name, only: names
          end
        end
      end
    end
  end
end
