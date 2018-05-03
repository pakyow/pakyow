# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Data
    class NotNullViolation < Pakyow::Error
    end

    class UniqueViolation < Pakyow::Error
    end
  end
end
