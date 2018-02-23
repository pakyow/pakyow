# frozen_string_literal: true

require "fileutils"

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
        ::Process.waitpid(::Process.spawn("bundle install"))
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
          @pid = ::Process.fork {
            # workaround for: https://bugs.ruby-lang.org/issues/14435
            ENV["TZ"] = local_timezone
            run_environment(port: port)
          }
        else
          # TODO: pass correct config options
          @pid = ::Process.spawn("bundle exec pakyow server --no-reload")
        end
      end

      def start_proxy(port)
        if instance_variable_defined?(:@proxy)
          return
        else
          @proxy = true
        end

        host = @server.host
        builder = Rack::Builder.new {
          run Proxy.new(port: port, host: host)
        }

        Pakyow.send(:handler, @server.server).run(builder.to_app, Host: @server.host, Port: @server.port)
      end

      def find_local_port
        server = TCPServer.new("127.0.0.1", 0)
        port = server.addr[1]
        server.close
        port
      end

      # Proxies requests to the underlying environment process..
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
            destination = "#{@host}:#{@port}"

            env["HTTP_HOST"] = destination

            response = HTTP.headers(
              parse_request_headers(env)
            ).send(
              env["REQUEST_METHOD"].downcase,
              File.join("#{env["rack.url_scheme"]}://#{destination}", env["REQUEST_URI"].to_s)
            )

            [response.status, parse_response_headers(response), response.body]
          else
            [404, {}, ["app not found"]]
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

        def parse_request_headers(env)
          env.select { |key, _|
            key.start_with? "HTTP_"
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
