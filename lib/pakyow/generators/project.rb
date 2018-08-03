# frozen_string_literal: true

require "securerandom"

require "pakyow/generator"
require "pakyow/version"

module Pakyow
  # @api private
  module Generators
    class Project < Generator
      after :generate do
        Bundler.with_clean_env do
          run "pwd && which bundle && bundle install --binstubs", message: "Bundling dependencies"
        end
      end

      def generating_locally?
        local_pakyow = Gem::Specification.sort_by { |g| [g.name.downcase, g.version] }.group_by(&:name).detect { |k, _| k == "pakyow" }
        !local_pakyow || local_pakyow.last.last.version < Gem::Version.new(Pakyow::VERSION)
      end

      def generate_session_secret
        SecureRandom.hex(64)
      end
    end
  end
end
