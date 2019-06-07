# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"

module Pakyow
  class App
    class Connection
      module Behavior
        module Verifier
          extend Support::Extension

          apply_extension do
            after "initialize" do
              session[:verifier_key] ||= Support::MessageVerifier.key
            end
          end

          def verifier
            unless instance_variable_defined?(:@verifier)
              @verifier = Support::MessageVerifier.new(verifier_key)
            end

            @verifier
          end

          def verifier_key
            session[:verifier_key]
          end
        end
      end
    end
  end
end
