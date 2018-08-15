# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Data
    class Error < Pakyow::Error
    end

    class ConstraintViolation < Error
    end

    class NotNullViolation < Error
    end

    class UniqueViolation < Error
    end

    class Rollback < Error
    end
  end
end
