require "pakyow/support/configurable/config_group"

module Pakyow
  module Support
    module Configurable
      class Config
        def initialize
          @groups = {}
        end

        def add_group(name, options, parent, &block)
          settings = ConfigGroup.new(name, options, parent, &block)
          @groups[name.to_sym] = settings
        end

        def method_missing(name)
          @groups[name]
        end

        def freeze
          super

          # TODO: freeze all the other things
        end
      end
    end
  end
end
