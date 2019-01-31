# frozen_string_literal: true

require "execjs"

module Pakyow
  module Assets
    class Babel
      def self.transform(content, **options)
        context.call("Babel.transform", content, options)
      end

      private

      def self.context
        @context ||= ExecJS.compile(
          File.read(
            File.expand_path("../../../../src/@babel/standalone@7.3.1/babel.js", __FILE__)
          )
        )
      end
    end
  end
end
