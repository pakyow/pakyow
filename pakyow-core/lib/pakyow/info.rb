# frozen_string_literal: true

require "pakyow/version"

module Pakyow
  # Returns information about the environment.
  #
  def self.info
    {
      versions: {
        ruby: "v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})",
        pakyow: "v#{VERSION}"
      },

      apps: Pakyow.mounts.map { |mount|
        {
          mount_path: mount[:path],
          class: mount[:app].to_s,
          reference: mount[:app].config.name.inspect,
          frameworks: mount[:app].config.loaded_frameworks,
          app_root: File.expand_path(mount[:app].config.root)
        }
      }
    }
  end
end
