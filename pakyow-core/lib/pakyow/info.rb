# frozen_string_literal: true

require_relative "version"

module Pakyow
  # Returns information about the environment.
  #
  def self.info
    {
      versions: {
        ruby: "v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})",
        pakyow: "v#{VERSION}"
      },

      apps: Pakyow.__mounts.map { |app, options|
        {
          mount_path: options[:path],
          class: app.to_s,
          reference: app.config.name.inspect,
          frameworks: app.config.loaded_frameworks,
          app_root: File.expand_path(app.config.root)
        }
      }
    }
  end
end
