# frozen_string_literal: true

command :info, :sources do
  describe "Show defined sources for an app"
  required :app
  required :cli

  action do
    require "pakyow/support/cli/style"
    require "pakyow/support/dependencies"

    sources = @app.sources.each.sort_by { |source|
      source.plural_name
    }

    source_names = sources.map { |source|
      source.plural_name
    }

    source_locations = sources.map { |source|
      source_location = source.source_location.join(":")

      source_location = if source_location.empty?
        "unknown"
      else
        Pakyow::Support::Dependencies.library_name(source_location) ||
          Pakyow::Support::Dependencies.strip_path_prefix(source_location)
      end

      if source_location.start_with?("pakyow-")
        Pakyow::Support::CLI.style.blue(
          "pakyow/#{source_location.split("pakyow-", 2)[1]}"
        )
      elsif source_location == "unknown"
        Pakyow::Support::CLI.style.italic(source_location)
      else
        source_location
      end
    }

    sources.each_with_index do |source, i|
      @cli.feedback.puts Pakyow::Support::CLI.style.bold(source_names[i].inspect) + " #{source_locations[i]}"

      source.associations.each do |association_type, associations|
        associations.each do |association|
          @cli.feedback.puts "  #{association_type} #{association.name.inspect}"
        end
      end

      if source.attributes.any? && source.associations.values.flatten.any?
        @cli.feedback.puts
      end

      if source.attributes.any?
        attributes = source.attributes.sort_by { |attribute_name, _|
          attribute_name
        }

        attributes.each do |attribute_name, attribute_type|
          @cli.feedback.puts "  attribute #{attribute_name.inspect}, #{attribute_type.meta[:mapping].inspect}"
        end
      end

      @cli.feedback.puts
    end
  end
end
