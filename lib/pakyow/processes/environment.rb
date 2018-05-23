# frozen_string_literal: true

require "fileutils"
require "tty-command"
require "tty-spinner"

require "pakyow/process"
require "pakyow/commands/server"

module Pakyow
  module Processes
    class Environment < Process
      # Other processes (e.g. apps) can touch this file to restart the server.
      #
      watch "./tmp/restart.txt"

      # Respawn the entire environment when the bundle changes.
      #
      watch "./Gemfile"
      on_change(/Gemfile/) do
        spinner = TTY::Spinner.new(":spinner Bundling ...", format: :dots)
        spinner.auto_spin

        result = TTY::Command.new(printer: :null, pty: true).run!("bundle install")

        if result.failure?
          spinner.error("failed:")
          puts result.out
        else
          spinner.stop(" done! Respawning ...\n")
          ::Process.kill("TERM", @proxy_pid)
          @server.respawn
        end
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
          run_environment
        else
          @proxy_port ||= find_local_port

          run_environment_subprocess(@proxy_port)

          # Register the pid for internal process management.
          #
          super

          start_proxy(@proxy_port)
        end
      end

      private

      def run_environment(port: @server.port, host: @server.host)
        Pakyow.setup(env: @server.env).run(port: port, host: host, server: @server.server)
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

              bundle exec pakyow server --standalone

          ERROR

          exit
        end
      end

      def start_proxy(port)
        unless @proxy_pid
          @proxy_pid = fork {
            host = @server.host
            builder = Rack::Builder.new {
              run Proxy.new(host: host, port: port)
            }

            Pakyow.send(:handler, @server.server).run(builder.to_app, Host: @server.host, Port: @server.port, Silent: true)
          }

          Pakyow::STOP_SIGNALS.each do |signal|
            trap(signal) {
              ::Process.kill("TERM", @proxy_pid); exit
            }
          end

          sleep
        end
      end

      def find_local_port
        server = TCPServer.new("127.0.0.1", 0)
        port = server.addr[1]
        server.close
        port
      end

      # Proxies requests to the underlying environment process.
      #
      class Proxy
        require "http"
        require "socket"
        require "timeout"

        def initialize(port:, host:)
          @port, @host = port, host
        end

        def call(env)
          if wait_or_timeout
            initial_request = Rack::Request.new(env)
            destination = "#{@host}:#{@port}"

            env["HTTP_HOST"] = destination

            response = HTTP.headers(
              parse_request_headers(env)
            ).send(
              env["REQUEST_METHOD"].downcase,
              File.join("#{env["rack.url_scheme"]}://#{destination}", env["REQUEST_URI"].to_s),
              body: initial_request.body
            )

            [response.status, parse_response_headers(response), response.body]
          else
            [404, {}, ["app did not respond"]]
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
