# frozen_string_literal: true

require "pakyow/version"

module Pakyow
  def self.info
    {
      versions: {
        ruby: "v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})",
        pakyow: "v#{VERSION}",
        rack: "v#{Rack.release}"
      },

      apps: Pakyow.mounts.map { |path, info|
        {
          mount_path: "/",
          class: info[:app].to_s,
          frameworks: info[:app].config.loaded_frameworks,
          app_root: File.expand_path(info[:app].config.root),
        }
      }
    }
  end
end
