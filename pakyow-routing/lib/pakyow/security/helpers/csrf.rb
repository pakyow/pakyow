# frozen_string_literal: true

require "pakyow/support/message_verifier"

module Pakyow
  module Security
    module Helpers
      module CSRF
        def authenticity_client_id
          @authenticity_client_id ||= Support::MessageVerifier.key
        end
      end
    end
  end
end
