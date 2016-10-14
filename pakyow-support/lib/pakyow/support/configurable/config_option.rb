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

        # TODO: would this work if `parent` was part of initialization or would that not be thread-safe?
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
