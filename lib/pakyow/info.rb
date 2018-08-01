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
        common_info = {
          mount_path: "/",
          class: info[:app].to_s,
        }

        if info[:app].ancestors.include?(Pakyow::App)
          common_info.merge(
            reference: info[:app].config.name.inspect,
            frameworks: info[:app].config.loaded_frameworks,
            app_root: File.expand_path(info[:app].config.root)
          )
        else
          common_info
        end
      }
    }
  end
end
