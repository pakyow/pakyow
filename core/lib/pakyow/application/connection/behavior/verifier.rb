# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"

module Pakyow
  class Application
    class Connection
      module Behavior
        module Verifier
          extend Support::Extension

          apply_extension do
            after "initialize" do
              if app.config.session.enabled
                session[:verifier_key] ||= Support::MessageVerifier.key
              end
            end
          end

          def verifier
            if app.top.config.session.enabled
              unless defined?(@verifier)
                @verifier = Support::MessageVerifier.new(verifier_key)
              end

              @verifier
            end
          end

          def verifier_key
            if app.top.config.session.enabled
              session[:verifier_key]
            end
          end
        end
      end
    end
  end
end
