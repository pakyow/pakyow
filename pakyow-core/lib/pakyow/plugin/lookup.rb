# frozen_string_literal: true

require "forwardable"

module Pakyow
  class Plugin
    # @api private
    class Lookup
      include Enumerable

      extend Forwardable
      def_delegator :@plugs, :each

      def initialize(plugs)
        @plugs = plugs

        plugs.map { |plug|
          plug.class.plugin_name
        }.uniq.each do |plugin_name|
          define_singleton_method plugin_name do |plugin_instance_name = :default|
            plugin_instance_name = plugin_instance_name.to_sym

            @plugs.find { |plug|
              plug.class.plugin_name == plugin_name && plug.__object_name.namespace.parts.last == plugin_instance_name
            }
          end
        end
      end
    end
  end
end
