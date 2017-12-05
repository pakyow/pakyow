# frozen_string_literal: true

require "pakyow/support/configurable/config_group"
require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      class Config
        using DeepDup

        attr_reader :groups

        def initialize
          @groups = {}
        end

        def initialize_copy(original)
          super

          @groups = @groups.deep_dup
        end

        def add_group(name, options, parent, &block)
          settings = ConfigGroup.new(name, options, parent, &block)
          @groups[name.to_sym] = settings
        end

        def method_missing(name)
          @groups[name]
        end

        def load_defaults(env)
          @groups.each do |_, group|
            next unless defaults = group.defaults(env)
            group.instance_eval(&defaults)
          end
        end

        def freeze
          super

          # TODO: freeze all the other things
        end
      end
    end
  end
end
