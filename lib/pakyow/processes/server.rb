# frozen_string_literal: true

require "fileutils"

require "pakyow/process"
require "pakyow/commands/server"

module Pakyow
  module Processes
    class Server < Process
      Pakyow::Commands::Server.register_process(self)

      # Other processes (e.g. apps) can touch this file to restart the server.
      #
      watch "./tmp/restart.txt"

      # Respawn the entire environment when the bundle changes.
      #
      on_change(/Gemfile/) do
        ::Process.waitpid(::Process.spawn("bundle install"))
        @server.respawn
      end

      watch "./Gemfile"

      def start
        if ::Process.respond_to?(:fork)
          local_timezone = Time.now.getlocal.zone
          @pid = ::Process.fork {
            # workaround for: https://bugs.ruby-lang.org/issues/14435
            ENV["TZ"] = local_timezone
            @server.start_standalone_server

            at_exit do
              @server.stop_dependent_processes(self.class)
            end
          }
        else
          @pid = ::Process.spawn("bundle exec pakyow server --no-reload")
        end

        super
      end
    end
  end
end
