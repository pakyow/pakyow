module Pakyow
  # Raised when no app context is available
  class NoContextError < StandardError; end

  # Raised when no config object is available
  class ConfigError < StandardError; end

  # Raised when route is looked up that doesn't exist
  class MissingRoute < StandardError; end

  # Raised when template part doesn't exist
  class UnknownTemplatePart < StandardError; end

  class Error < StandardError; end
end

