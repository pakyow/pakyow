require "securerandom"
require "pakyow/version"

module Pakyow
  # @api private
  module Generators
    class AppGenerator < Thor::Group
      include Thor::Actions

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

      protected

      def generating_locally?
        local_pakyow = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }.detect{|k,v| k == "pakyow"}
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
