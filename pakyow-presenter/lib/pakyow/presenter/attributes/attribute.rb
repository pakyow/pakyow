# frozen_string_literal: true

module Pakyow
  module Presenter
    class Attributes
      class Attribute
        def initialize(value)
          @value = value
        end

        def initialize_copy(_)
          @value = @value.dup
        end

        def ==(other)
          @value == other
        end
      end
    end
  end
end
