# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/command"

module Pakyow
  module Behavior
    module Commands
      extend Support::Extension

      apply_extension do
        configurable :commands do
          setting :paths, ["./commands", File.expand_path("../../commands", __FILE__)]
          setting :prelaunch, []
        end

        definable :command, Command, builder: -> (*namespace, object_name, **opts) {
          opts[:cli_name] = (namespace + [object_name]).join(":")

          return namespace, object_name, opts
        }, lookup: -> (_app, command, **values) {
          command.call(**values)
        }

        # @api private
        def load_commands
          config.commands.paths.uniq.each_with_object(commands) do |commands_path, commands|
            Dir.glob(File.join(File.expand_path(commands_path), "**/*.rb")).each do |command_path|
              Kernel.load command_path
            end
          end
        end
      end
    end
  end
end
