# frozen_string_literal: true

require "fileutils"

require "pakyow/process"

require "pakyow/support/cli/runner"
require "pakyow/support/cli/style"

module Pakyow
  module Processes
    class Environment < Process
      # Other processes (e.g. apps) can touch this file to restart the server.
      #
      watch "./tmp/restart.txt"

      # Automatically bundle.
      #
      watch "./Gemfile"
      on_change(/Gemfile$/) do
        Support::CLI::Runner.new(message: "Bundling").run("bundle install")
      end

      # Respawn when the bundle changes.
      #
      watch "./Gemfile.lock"
      on_change(/Gemfile.lock/) do
        @server.respawn
      end

      # Respawn when something about the environment changes.
      #
      # FIXME: this doesn't need to be hardcoded; make it a config setting
      #
      watch "./config/environment.rb"
      on_change(/config\/environment.rb/) do
        @server.respawn
      end

      def start
        if @server.standalone?
          run_environment do
            puts running_text
          end
        else
          @proxy_port ||= find_local_port

          run_environment_subprocess(@proxy_port)

          # Register the pid for internal process management.
          #
          super

          if !@proxy_pid
            start_proxy(@proxy_port)
          end
        end
      end

      def stop(exiting = false)
        super

        if exiting
          stop_proxy
        end
      end

      private

      def run_environment(port: @server.port, host: @server.host, &block)
        Pakyow.run(port: port, host: host, server: @server.server, &block)
      end

      def run_environment_subprocess(port)
        if ::Process.respond_to?(:fork)
          local_timezone = Time.now.getlocal.zone
          @pid = fork {
            # workaround for: https://bugs.ruby-lang.org/issues/14435
            ENV["TZ"] = local_timezone
            run_environment(port: port)
          }
        else
          puts <<~ERROR

            Reloading is only supported on platforms that support process forking.

            Please use the standalone server instead:

              pakyow boot --standalone

          ERROR

          exit
        end
      end

      def start_proxy(port)
        @proxy_pid = fork {
          server_host = @server.host || Pakyow.config.server.host
          server_port = @server.port || Pakyow.config.server.port

          builder = Rack::Builder.new {
            run Proxy.new(host: server_host, port: port, forwarded: "#{server_host}:#{server_port}")
          }

          Pakyow.send(:handler, @server.server).run(builder.to_app, Host: server_host, Port: server_port, Silent: true) do
            puts running_text(host: server_host, port: server_port) unless ENV.key?("PW_RESPAWN")
          end
        }

        Pakyow::STOP_SIGNALS.each do |signal|
          trap(signal) {
            @server.stop
            raise SignalException, signal
          }
        end

        sleep
      end

      def stop_proxy
        if @proxy_pid
          ::Process.kill("TERM", @proxy_pid)
          ::Process.waitpid(@proxy_pid)
          @proxy_pid = nil
        end
      end

      def find_local_port
        server = TCPServer.new("127.0.0.1", 0)
        port = server.addr[1]
        server.close
        port
      end

      def running_text(host: Pakyow.host, port: Pakyow.port)
        text = String.new("Pakyow › #{Pakyow.env.capitalize}")
        text << " › http://#{host}:#{port}" if host && port

        Support::CLI.style.blue.bold(
          text
        ) + Support::CLI.style.italic("\nUse Ctrl-C to stop the project.")
      end

      # Proxies requests to the underlying environment process.
      #
      class Proxy
        require "http"
        require "socket"
        require "timeout"

        def initialize(port:, host:, forwarded:)
          @port, @host, @forwarded = port, host, forwarded
        end

        # Interval to retry a request that failed (likely due to a restart).
        #
        RETRY_EVERY = 0.25

        # How long to retry before letting the request fail.
        #
        RETRY_OVER_SECONDS = 5

        def call(env, retry_count = 0)
          if wait_or_timeout
            request = Rack::Request.new(env)
            destination = "#{@host}:#{@port}"

            env["HTTP_HOST"] = destination

            response = HTTP.headers(
              parse_request_headers(env).merge("X-Forwarded-Host" => @forwarded)
            ).send(
              env["REQUEST_METHOD"].downcase,
              File.join("#{env["rack.url_scheme"]}://#{destination}", env["REQUEST_URI"].to_s),
              body: request.body
            )

            [response.status, parse_response_headers(response), response.body]
          else
            [404, {}, ["app did not respond"]]
          end
        rescue HTTP::ConnectionError => error
          if retry_count > RETRY_OVER_SECONDS / RETRY_EVERY
            raise error
          else
            sleep RETRY_EVERY
            call(env, retry_count + 1)
          end
        end

        private

        def wait_or_timeout(total_waits = 0)
          if port_open?(@host, @port)
            true
          else
            if total_waits == 30
              false
            else
              sleep 0.5; wait_or_timeout(total_waits + 1)
            end
          end
        end

        def port_open?(ip, port, seconds = 1)
          Timeout::timeout(seconds) do
            begin
              TCPSocket.new(ip, port).close
              true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              false
            end
          end
        rescue Timeout::Error
          false
        end

        PASSED_REQUEST_HEADERS = [
          "CONTENT_TYPE"
        ]

        def parse_request_headers(env)
          env.select { |key, _|
            key.start_with?("HTTP_") || PASSED_REQUEST_HEADERS.include?(key)
          }.each_with_object({}) { |arr, headers|
            key, value = arr
            headers[key.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-")] = value
          }
        end

        REJECTED_RESPONSE_HEADERS = [
          "connection",
          "keep-alive",
          "proxy-authenticate",
          "proxy-authorization",
          "te",
          "trailer",
          "transfer-encoding",
          "upgrade"
        ].freeze

        def parse_response_headers(response)
          response.headers.to_h.reject { |header|
            REJECTED_RESPONSE_HEADERS.include? header.downcase
          }
        end
      end
    end
  end
end
