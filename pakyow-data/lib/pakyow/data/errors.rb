# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Data
    class ConstraintViolation < Pakyow::Error
    end

    class NotNullViolation < Pakyow::Error
    end

    class UniqueViolation < Pakyow::Error
    end
  end
end
