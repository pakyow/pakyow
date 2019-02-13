# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          setting :default_env, :development
          setting :freeze_on_boot, true
          setting :exit_on_boot_failure, true
          setting :timezone, :utc

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

          configurable :server do
            setting :name, :puma
            setting :host, "localhost"
            setting :port, 3000
          end

          configurable :cli do
            setting :repl, IRB
          end

          configurable :logger do
            setting :enabled, true
            setting :level, :debug
            setting :formatter do
              require "pakyow/logger/formatters/human"
              Logger::Formatters::Human
            end

            setting :destinations do
              if config.logger.enabled
                [$stdout]
              else
                []
              end
            end

            defaults :test do
              setting :enabled, false
            end

            defaults :production do
              setting :level, :info
              setting :formatter do
                require "pakyow/logger/formatters/logfmt"
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
          end

          configurable :tasks do
            setting :paths, ["./tasks", File.expand_path("../../../tasks", __FILE__)]
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

          configurable :puma do
            setting :host do
              config.server.host
            end

            setting :port do
              config.server.port
            end

            setting :binds, []
            setting :min_threads, 5
            setting :max_threads, 5
            setting :workers, 0
            setting :worker_timeout, 60

            setting :on_restart do
              []
            end

            setting :before_fork do
              []
            end

            setting :before_worker_fork do
              [
                lambda { |_| Pakyow.forking }
              ]
            end

            setting :after_worker_fork do
              []
            end

            setting :before_worker_boot do
              [
                lambda { |_| Pakyow.forked }
              ]
            end

            setting :before_worker_shutdown do
              []
            end

            setting :silent, true

            defaults :production do
              setting :silent, false

              setting :host do
                if config.puma.binds.to_a.any?
                  nil
                else
                  ENV["HOST"] || config.server.host
                end
              end

              setting :port do
                if config.puma.binds.to_a.any?
                  nil
                else
                  ENV["PORT"] || config.server.port
                end
              end

              setting :binds do
                [ENV["BIND"]].compact
              end

              setting :min_threads do
                ENV["THREADS"] || 5
              end

              setting :max_threads do
                ENV["THREADS"] || 5
              end

              setting :workers do
                ENV["WORKERS"] || 5
              end
            end
          end
        end
      end
    end
  end
end
