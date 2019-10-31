# frozen_string_literal: true

module Pakyow
  module Support
    # Information about the local system.
    #
    # @api private
    module System
      module_function

      def pwd
        @pwd ||= Pathname.new(File.expand_path("."))
      end

      def gemfile
        @gemfile ||= pwd.join("Gemfile")
      end

      def gemfile?
        gemfile.exist?
      end
    end
  end
end
