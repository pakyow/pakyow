require "pakyow/presenter/attributes/attribute"

module Pakyow
  module Presenter
    module Attributes
      # Wraps the value for a string-type view attribute (e.g. href).
      #
      # Behaves just like a normal +String+.
      #
      class String < Attribute
        def self.parse(value)
          new(value.to_s)
        end
      end
    end
  end
end
