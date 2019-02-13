RSpec.describe Pakyow do
  describe "configuration options" do
    describe "environment_path" do
      it "has a default value" do
        expect(Pakyow.config.environment_path).to eq(File.join(Pakyow.config.root, "config/environment"))
      end
    end

    describe "default_env" do
      it "has a default value" do
        expect(Pakyow.config.default_env).to eq(:development)
      end
    end

    describe "exit_on_boot_failure" do
      it "has a default value" do
        expect(Pakyow.config.exit_on_boot_failure).to eq(true)
      end

      context "in test" do
        before do
          Pakyow.configure!(:test)
        end

        it "defaults to false" do
          expect(Pakyow.config.exit_on_boot_failure).to eq(false)
        end
      end
    end

    describe "timezone" do
      it "has a default value" do
        expect(Pakyow.config.timezone).to eq(:utc)
      end
    end

    describe "server.name" do
      it "has a default value" do
        expect(Pakyow.config.server.name).to eq(:puma)
      end
    end

    describe "server.port" do
      it "has a default value" do
        expect(Pakyow.config.server.port).to eq(3000)
      end
    end

    describe "server.host" do
      it "has a default value" do
        expect(Pakyow.config.server.host).to eq("localhost")
      end
    end

    describe "cli.repl" do
      it "has a default value" do
        expect(Pakyow.config.cli.repl).to eq(IRB)
      end
    end

    describe "logger.enabled" do
      it "has a default value" do
        expect(Pakyow.config.logger.enabled).to eq(true)
      end

      context "in test" do
        before do
          Pakyow.configure!(:test)
        end

        it "defaults to false" do
          expect(Pakyow.config.logger.enabled).to eq(false)
        end
      end

      context "in ludicrous" do
        before do
          Pakyow.configure!(:ludicrous)
        end

        it "defaults to false" do
          expect(Pakyow.config.logger.enabled).to eq(false)
        end
      end
    end

    describe "logger.level" do
      it "has a default value" do
        expect(Pakyow.config.logger.level).to eq(:debug)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to info" do
          expect(Pakyow.config.logger.level).to eq(:info)
        end
      end
    end

    describe "logger.formatter" do
      it "has a default value" do
        expect(Pakyow.config.logger.formatter).to eq(Pakyow::Logger::Formatters::Human)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to logfmt" do
          expect(Pakyow.config.logger.formatter).to eq(Pakyow::Logger::Formatters::Logfmt)
        end
      end
    end

    describe "logger.destinations" do
      context "when logger is enabled" do
        before do
          Pakyow.config.logger.enabled = true
        end

        it "defaults to stdout" do
          expect(Pakyow.config.logger.destinations).to eq([$stdout])
        end
      end

      context "when logger is disabled" do
        before do
          Pakyow.config.logger.enabled = false
        end

        it "defaults to empty" do
          expect(Pakyow.config.logger.destinations).to eq([])
        end
      end
    end

    describe "normalizer.strict_path" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_path).to eq(true)
      end
    end

    describe "normalizer.strict_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_www).to eq(false)
      end
    end

    describe "normalizer.require_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.require_www).to eq(true)
      end
    end

    describe "tasks.paths" do
      it "has a default value" do
        expect(Pakyow.config.tasks.paths).to eq(["./tasks", File.expand_path("../../../../lib/pakyow/tasks", __FILE__)])
      end
    end

    describe "tasks.prelaunch" do
      it "has a default value" do
        expect(Pakyow.config.tasks.prelaunch).to eq([])
      end
    end

    describe "redis.connection.url" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.url).to eq("redis://127.0.0.1:6379")
      end

      context "REDIS_URL is set" do
        before do
          ENV["REDIS_URL"] = "worked"
        end

        after do
          ENV.delete("REDIS_URL")
        end

        it "uses REDIS_URL" do
          expect(Pakyow.config.redis.connection.url).to eq("worked")
        end
      end
    end

    describe "redis.connection.timeout" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.timeout).to eq(5)
      end
    end

    describe "redis.connection.driver" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.driver).to eq(nil)
      end
    end

    describe "redis.connection.id" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.id).to eq(nil)
      end
    end

    describe "redis.connection.tcp_keepalive" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.tcp_keepalive).to eq(5)
      end
    end

    describe "redis.connection.reconnect_attempts" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.reconnect_attempts).to eq(1)
      end
    end

    describe "redis.connection.inherit_socket" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.inherit_socket).to eq(false)
      end
    end

    describe "redis.pool.size" do
      it "has a default value" do
        expect(Pakyow.config.redis.pool.size).to eq(3)
      end
    end

    describe "redis.pool.timeout" do
      it "has a default value" do
        expect(Pakyow.config.redis.pool.timeout).to eq(1)
      end
    end

    describe "redis.key_prefix" do
      it "has a default value" do
        expect(Pakyow.config.redis.key_prefix).to eq("pw")
      end
    end

    describe "puma.host" do
      it "has a default value" do
        expect(Pakyow.config.puma.host).to eq(
          Pakyow.config.server.host
        )
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "binds is not empty" do
          before do
            Pakyow.config.puma.binds = ["foo"]
          end

          it "has a default value" do
            expect(Pakyow.config.puma.host).to be(nil)
          end
        end

        context "HOST is set" do
          before do
            ENV["HOST"] = "foo"
          end

          after do
            ENV.delete("HOST")
          end

          it "defaults to HOST" do
            expect(Pakyow.config.puma.host).to eq("foo")
          end

          context "binds is not empty" do
            before do
              Pakyow.config.puma.binds = ["foo"]
            end

            it "has a default value" do
              expect(Pakyow.config.puma.host).to be(nil)
            end
          end
        end
      end
    end

    describe "puma.port" do
      it "has a default value" do
        expect(Pakyow.config.puma.port).to eq(
          Pakyow.config.server.port
        )
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "binds is not empty" do
          before do
            Pakyow.config.puma.binds = ["foo"]
          end

          it "has a default value" do
            expect(Pakyow.config.puma.port).to be(nil)
          end
        end

        context "PORT is set" do
          before do
            ENV["PORT"] = "4242"
          end

          after do
            ENV.delete("PORT")
          end

          it "defaults to PORT" do
            expect(Pakyow.config.puma.port).to eq("4242")
          end

          context "binds is not empty" do
            before do
              Pakyow.config.puma.binds = ["foo"]
            end

            it "has a default value" do
              expect(Pakyow.config.puma.port).to be(nil)
            end
          end
        end
      end
    end

    describe "puma.binds" do
      it "has a default value" do
        expect(Pakyow.config.puma.binds).to eq([])
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "BIND is set" do
          before do
            ENV["BIND"] = "unix://"
          end

          after do
            ENV.delete("BIND")
          end

          it "includes BIND" do
            expect(Pakyow.config.puma.binds).to eq(["unix://"])
          end
        end
      end
    end

    describe "puma.min_threads" do
      it "has a default value" do
        expect(Pakyow.config.puma.min_threads).to eq(5)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "THREADS is set" do
          before do
            ENV["THREADS"] = "10"
          end

          after do
            ENV.delete("THREADS")
          end

          it "defaults to THREADS" do
            expect(Pakyow.config.puma.min_threads).to eq("10")
          end
        end
      end
    end

    describe "puma.max_threads" do
      it "has a default value" do
        expect(Pakyow.config.puma.max_threads).to eq(5)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "THREADS is set" do
          before do
            ENV["THREADS"] = "15"
          end

          after do
            ENV.delete("THREADS")
          end

          it "defaults to THREADS" do
            expect(Pakyow.config.puma.min_threads).to eq("15")
          end
        end
      end
    end

    describe "puma.workers" do
      it "has a default value" do
        expect(Pakyow.config.puma.workers).to eq(0)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        context "WORKERS is set" do
          before do
            ENV["WORKERS"] = "42"
          end

          after do
            ENV.delete("WORKERS")
          end

          it "defaults to WORKERS" do
            expect(Pakyow.config.puma.workers).to eq("42")
          end
        end
      end
    end

    describe "puma.worker_timeout" do
      it "has a default value" do
        expect(Pakyow.config.puma.worker_timeout).to eq(60)
      end
    end

    describe "puma.on_restart" do
      it "has a default value" do
        expect(Pakyow.config.puma.on_restart).to eq([])
      end
    end

    describe "puma.before_fork" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_fork).to eq([])
      end
    end

    describe "puma.before_worker_boot" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_fork.count).to be(1)

        expect(Pakyow).to receive(:forking)
        Pakyow.config.puma.before_worker_fork[0].call(nil)
      end
    end

    describe "puma.after_worker_fork" do
      it "has a default value" do
        expect(Pakyow.config.puma.after_worker_fork).to eq([])
      end
    end

    describe "puma.before_worker_boot" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_boot.count).to be(1)

        expect(Pakyow).to receive(:forked)
        Pakyow.config.puma.before_worker_boot[0].call(nil)
      end
    end

    describe "puma.before_worker_shutdown" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_shutdown).to eq([])
      end
    end

    describe "puma.silent" do
      it "has a default value" do
        expect(Pakyow.config.puma.silent).to be(true)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "has a default value" do
          expect(Pakyow.config.puma.silent).to be(false)
        end
      end
    end
  end
end
