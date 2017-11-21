# frozen_string_literal: true

require "pakyow/support/safe_string"

module Pakyow
  # Methods available throughout an app.
  #
  # @api public
  module Helpers
    include Support::SafeStringHelpers
  end
end
