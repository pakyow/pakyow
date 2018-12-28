# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Assets
    class Error < Pakyow::Error
    end

    class UnknownExternalAsset < Error
      MESSAGES = {
        default: "`{asset}' is not a known external asset"
      }.freeze
    end
  end
end
