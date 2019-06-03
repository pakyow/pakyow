# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

require "pakyow/presenter/attributes/attribute"

module Pakyow
  module Presenter
    class Attributes
      # Wraps the value for a string-type view attribute (e.g. href).
      #
      # Behaves just like a normal +String+.
      #
      class String < Attribute
        extend Forwardable
        def_delegators :@value, :empty?, :include?

        def to_s
          @value
        end

        def to_str
          to_s
        end

        class << self
          include Support::SafeStringHelpers

          def parse(value)
            new(ensure_html_safety(value.to_s))
          end
        end
      end
    end
  end
end
