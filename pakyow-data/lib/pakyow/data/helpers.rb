# frozen_string_literal: true

module Pakyow
  module Helpers
    # TODO: move this to a Data::VerificationHelpers module
    def verify(&block)
      request.verify(&block)
    end
  end
end
