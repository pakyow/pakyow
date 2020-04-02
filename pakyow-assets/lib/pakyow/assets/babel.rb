# frozen_string_literal: true

require "mini_racer"
require "execjs"

require "pakyow/support/inflector"

module Pakyow
  module Assets
    class Babel
      def self.transform(content, **options)
        context.call("Babel.transform", content, camelize_keys(options))
      end

      private

      def self.context
        @context ||= ExecJS.compile(
          File.read(
            File.expand_path("../../../../src/@babel/standalone@7.9.4/babel.js", __FILE__)
          )
        )
      end

      def self.camelize_keys(options)
        Hash[options.map { |key, value|
          key = Support.inflector.camelize(key)
          key = key[0, 1].downcase + key[1..-1]
          [key, value]
        }]
      end
    end
  end
end
