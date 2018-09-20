# frozen_string_literal: true

require "pakyow/loader"

module Pakyow
  class Plugin
    # @api private
    class State
      def initialize(plugin, path: plugin.class.plugin_path)
        @plugin, @path = plugin, path
      end

      def backend_path(aspect)
        File.join(@path, "backend", aspect.to_s)
      end
    end
  end
end
