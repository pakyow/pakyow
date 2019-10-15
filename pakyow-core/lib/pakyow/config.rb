# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/logger/formatters/human"
require "pakyow/logger/formatters/logfmt"

module Pakyow
  module Config
    extend Support::Extension

    apply_extension do
      setting :default_env, :development
      setting :freeze_on_boot, true
      setting :exit_on_boot_failure, true
      setting :timezone, :utc
      setting :secrets, ["pakyow"]

      setting :connection_class do
        require "pakyow/connection"
        Connection
      end

      setting :root do
        File.expand_path(".")
      end

      setting :lib do
        File.join(config.root, "lib")
      end

      setting :environment_path do
        File.join(config.root, "config/environment")
      end

      setting :loader_path do
        File.join(config.root, "config/loader")
      end

      defaults :test do
        setting :exit_on_boot_failure, false
      end

      defaults :production do
        setting :secrets, [ENV["SECRET"].to_s.strip]
      end

      configurable :server do
        setting :host, "localhost"
        setting :port, 3000
        setting :count, 1
        setting :proxy, true

        defaults :production do
          setting :proxy, false

          setting :host do
            ENV["HOST"] || "0.0.0.0"
          end

          setting :port do
            ENV["PORT"] || 3000
          end

          setting :count do
            ENV["WORKERS"] || 5
          end
        end
      end

      configurable :cli do
        setting :repl do
          require "irb"; IRB
        end
      end

      configurable :logger do
        setting :enabled, true
        setting :sync, true

        setting :level do
          if config.logger.enabled
            :debug
          else
            :off
          end
        end

        setting :formatter do
          Logger::Formatters::Human
        end

        setting :destinations do
          if config.logger.enabled
            { stdout: $stdout }
          else
            {}
          end
        end

        defaults :test do
          setting :enabled, false
        end

        defaults :production do
          setting :level do
            if config.logger.enabled
              :info
            else
              :off
            end
          end

          setting :formatter do
            Logger::Formatters::Logfmt
          end
        end

        defaults :ludicrous do
          setting :enabled, false
        end
      end

      configurable :normalizer do
        setting :strict_path, true

        setting :strict_www, false
        setting :require_www, true

        setting :strict_https, false
        setting :require_https, true
        setting :allowed_http_hosts, ["localhost"]

        defaults :production do
          setting :strict_https, true
        end
      end

      configurable :tasks do
        setting :paths, ["./tasks", File.expand_path("../tasks", __FILE__)]
        setting :prelaunch, []
      end

      configurable :redis do
        configurable :connection do
          setting :url do
            ENV["REDIS_URL"] || "redis://127.0.0.1:6379"
          end

          setting :timeout, 5
          setting :driver, nil
          setting :id, nil
          setting :tcp_keepalive, 5
          setting :reconnect_attempts, 1
          setting :inherit_socket, false
        end

        configurable :pool do
          setting :size, 3
          setting :timeout, 1
        end

        setting :key_prefix, "pw"
      end

      configurable :cookies do
        setting :domain
        setting :path, "/"
        setting :max_age
        setting :expires
        setting :secure
        setting :http_only
        setting :same_site
      end
    end
  end
end
