module Pakyow
  # Raised when no app context is available
  class NoContextError < Error; end

  # Raised when route is looked up that doesn't exist
  class MissingRoute < Error; end

  # Raised when template part doesn't exist
  class UnknownTemplatePart < Error; end
end

