# frozen_string_literal: true

module Pakyow
  class Plugin
    # @api private
    class Lookup
      def initialize(plugs)
        @plugs = plugs

        plugs.map { |plug|
          plug.class.plugin_name
        }.uniq.each do |plugin_name|
          define_singleton_method plugin_name do |plugin_instance_name = :default|
            plugin_instance_name = plugin_instance_name.to_sym

            @plugs.find { |plug|
              plug.class.plugin_name == plugin_name && plug.__object_name.name == plugin_instance_name
            }
          end
        end
      end
    end
  end
end
