# frozen_string_literal: true

module Pakyow
  # Base Pakyow error object
  #
  # @api public
  class Error < StandardError
    attr_accessor :wrapped_exception, :context

    # @api private
    def cause
      wrapped_exception || super
    end
  end

  # @api private
  def self.build_error(exception, klass, context: nil)
    return exception if exception.is_a?(klass)

    error = klass.new("#{exception.class}: #{exception.message}")
    error.wrapped_exception = exception
    error.context = context
    error.set_backtrace(exception.backtrace)

    error
  end
end
