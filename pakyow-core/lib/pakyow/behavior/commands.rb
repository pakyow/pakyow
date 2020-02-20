# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/command"
require "pakyow/loader"

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

          unless opts.include?(:boot)
            opts[:boot] = true
          end

          return namespace, object_name, opts
        }, lookup: -> (_app, command, **values) {
          command.call(**values)
        }

        on "load" do
          config.commands.paths.uniq.each_with_object(commands) do |commands_path, commands|
            Loader.load_path(File.expand_path(commands_path), target: Pakyow)
          end
        end
      end
    end
  end
end
