module Pakyow
  # Raised when no app context is available
  class NoContextError < StandardError; end

  # Raised when route is looked up that doesn't exist
  class MissingRoute < StandardError; end

  class Error < StandardError; end
end

