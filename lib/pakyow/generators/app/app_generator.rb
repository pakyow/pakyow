# frozen_string_literal: true

require "securerandom"

require "pakyow/generator"
require "pakyow/version"

module Pakyow
  # @api private
  module Generators
    class AppGenerator < Generator
      def self.source_root
        File.expand_path("../", __FILE__)
      end

      argument :name

      def create_project
        directory "templates", name
      end

      def bundle_install
        run "bundle install --binstubs"
      end

      def dot
        "."
      end

      def done
        puts "Done! Run `cd #{name}; bundle exec pakyow server` to get started!"
      end

      protected

      def generating_locally?
        local_pakyow = Gem::Specification.sort_by { |g| [g.name.downcase, g.version] }.group_by(&:name).detect { |k, _| k == "pakyow" }
        !local_pakyow || local_pakyow.last.last.version < Gem::Version.new(Pakyow::VERSION)
      end

      def generate_session_secret
        SecureRandom.hex(64)
      end

      def app_name
        File.basename(name)
      end
    end
  end
end
