# frozen_string_literal: true

module Pakyow
  module Support
    # Information about the local system.
    #
    # @api private
    module System
      module_function

      def current_path
        @__current_path ||= Pathname.new(File.expand_path("."))
      end

      def gemfile_path
        @__gemfile_path ||= current_path.join("Gemfile")
      end

      def gemfile?
        gemfile_path.exist?
      end
    end
  end
end
