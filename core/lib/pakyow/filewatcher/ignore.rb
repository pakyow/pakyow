# frozen_string_literal: true

module Pakyow
  class Filewatcher
    # @api private
    class Ignore
      class << self
        def build(object)
          case object
          when ::String
            Ignores::Pathname.new(::Pathname.new(object))
          when ::Pathname
            Ignores::Pathname.new(object)
          when ::Regexp
            Ignores::Regexp.new(object)
          when Ignore
            object
          else
            raise ArgumentError, "unsure how to ignore `#{object}'"
          end
        end
      end
    end

    # @api private
    module Ignores
      class Pathname < Ignore
        def initialize(path)
          @paths = Dir.glob(path)
        end

        def match?(path)
          @paths.include?(path)
        end
      end

      class Regexp < Ignore
        def initialize(regexp)
          @regexp = regexp
        end

        def match?(path)
          @regexp.match?(path)
        end
      end
    end
  end
end
