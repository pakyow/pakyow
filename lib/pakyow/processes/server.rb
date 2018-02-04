# frozen_string_literal: true

require "pakyow/process"

module Pakyow
  module Processes
    class Server < Process
      Pakyow::Commands::Server.register_process(self)

      watch "."

      on_change(/Gemfile/) do
        ::Process.waitpid(::Process.spawn("bundle install"))
        @server.respawn
      end

      def start
        if ::Process.respond_to?(:fork)
          local_timezone = Time.now.getlocal.zone
          @pid = ::Process.fork {
            # workaround for: https://bugs.ruby-lang.org/issues/14435
            ENV["TZ"] = local_timezone
            @server.start_standalone_server
          }
        else
          @pid = ::Process.spawn("bundle exec pakyow server --no-reload")
        end

        super
      end
    end
  end
end
