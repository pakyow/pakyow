# frozen_string_literal: true

require "pakyow/support/cli/style"
require "pakyow/support/dependencies"

desc "Show defined endpoints for an app"
namespace :info do
  task :endpoints, [:app] do |_, args|
    endpoint_methods = args[:app].endpoints.map { |endpoint|
      endpoint.method.to_s.upcase
    }

    longest_endpoint_method = endpoint_methods.max { |a, b|
      a.length <=> b.length
    }

    endpoint_names = args[:app].endpoints.map { |endpoint|
      endpoint.name
    }

    longest_endpoint_name = endpoint_names.max { |a, b|
      a.to_s.length <=> b.to_s.length
    }

    endpoint_paths = args[:app].endpoints.map { |endpoint|
      endpoint.path
    }

    longest_endpoint_path = endpoint_paths.max { |a, b|
      a.to_s.length <=> b.to_s.length
    }

    endpoint_sources = args[:app].endpoints.map { |endpoint|
      source_location = endpoint.source_location.join(":")
      if source_location.empty?
        "unknown"
      else
        Pakyow::Support::Dependencies.library_name(source_location) ||
          Pakyow::Support::Dependencies.strip_path_prefix(source_location)
      end
    }

    longest_endpoint_source = endpoint_sources.max { |a, b|
      a.to_s.length <=> b.to_s.length
    }

    puts endpoint_names.map(&:to_s).each_with_index.map { |endpoint_name, i|
      if endpoint_name.start_with?("@") || endpoint_name.end_with?("_default")
        nil
      else
        source = endpoint_sources[i]

        source = if source.start_with?("pakyow-")
          Pakyow::Support::CLI.style.blue(
            "pakyow/#{source.split("pakyow-", 2)[1]}"
          )
        elsif source == "unknown"
          Pakyow::Support::CLI.style.italic(source)
        else
          source
        end

        [
          ":#{endpoint_name.ljust(longest_endpoint_name.length)}",
          endpoint_methods[i].ljust(longest_endpoint_method.length),
          endpoint_paths[i].ljust(longest_endpoint_path.length),
          source.ljust(longest_endpoint_source.length)
        ].join("  ")
      end
    }.compact.sort
  end
end
