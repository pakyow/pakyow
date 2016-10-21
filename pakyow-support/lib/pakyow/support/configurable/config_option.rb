module Pakyow
  module Support
    module Configurable
      class ConfigOption
        attr_reader :name
        attr_writer :value

        def initialize(name, default)
          @name = name
          @default = default
        end

        def value(parent)
          @value || default(parent)
        end

        def default(parent)
          if @default.is_a?(Proc)
            parent.instance_eval(&@default)
          else
            @default
          end
        end
      end
    end
  end
end
