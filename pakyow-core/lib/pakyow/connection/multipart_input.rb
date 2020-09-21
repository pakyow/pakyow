# frozen_string_literal: true

require "delegate"

module Pakyow
  class Connection
    class MultipartInput < SimpleDelegator
      attr_reader :filename, :headers, :type

      def initialize(filename:, headers:, type:)
        @filename, @headers, @type = filename, headers, type
        __setobj__(Tempfile.new(["PakyowMultipart", File.extname(filename)]))
      end

      alias_method :media_type, :type

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end
    end
  end
end
