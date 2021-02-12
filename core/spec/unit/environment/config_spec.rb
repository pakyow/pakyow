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

    describe "timezone" do
      it "has a default value" do
        expect(Pakyow.config.timezone).to eq(:utc)
      end
    end

    describe "mounts" do
      it "has a default value" do
        expect(Pakyow.config.mounts).to eq(:all)
      end
    end

    describe "channel" do
      it "has a default value" do
        expect(Pakyow.config.channel).to eq(:default)
      end
    end

    describe "secrets" do
      it "has a default value" do
        expect(Pakyow.config.secrets).to eq(["pakyow"])
      end

      context "in production" do
        before do
          ENV["SECRET"] = secret
          Pakyow.configure!(:production)
        end

        after do
          ENV.delete("SECRET")
        end

        let :secret do
          "sekret"
        end

        it "defaults to SECRET" do
          expect(Pakyow.config.secrets).to eq([secret])
        end

        context "SECRET is not set" do
          let :secret do
            nil
          end

          it "defaults to an empty string" do
            expect(Pakyow.config.secrets).to eq([""])
          end
        end

        context "SECRET has extra whitespace" do
          let :secret do
            "sekret  "
          end

          it "strips the whitespace" do
            expect(Pakyow.config.secrets).to eq(["sekret"])
          end
        end
      end
    end

    describe "multiapp_path" do
      it "has a default value" do
        expect(Pakyow.config.multiapp_path).to eq(File.join(Pakyow.config.root, "apps"))
      end
    end

    describe "common_path" do
      it "has a default value" do
        expect(Pakyow.config.common_path).to eq(File.join(Pakyow.config.root, "common"))
      end
    end

    describe "common_src" do
      it "has a default value" do
        expect(Pakyow.config.common_src).to eq(File.join(Pakyow.config.root, "common/backend"))
      end
    end

    describe "common_lib" do
      it "has a default value" do
        expect(Pakyow.config.common_lib).to eq(File.join(Pakyow.config.root, "common/lib"))
      end
    end

    describe "polite" do
      it "has a default value" do
        expect(Pakyow.config.polite).to be(true)
      end
    end

    describe "cli.repl" do
      it "has a default value" do
        expect(Pakyow.config.cli.repl).to eq(IRB)
      end
    end

    describe "logger.sync" do
      it "has a default value" do
        expect(Pakyow.config.logger.sync).to eq(true)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to false" do
          expect(Pakyow.config.logger.sync).to eq(false)
        end
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
          expect(Pakyow.config.logger.destinations.count).to eq(1)
          expect(Pakyow.config.logger.destinations[:stdout]).to eq($stdout)
        end
      end

      context "when logger is disabled" do
        before do
          Pakyow.config.logger.enabled = false
        end

        it "defaults to empty" do
          expect(Pakyow.config.logger.destinations).to eq({})
        end
      end
    end

    describe "normalizer.canonical_uri" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.canonical_uri).to eq(nil)
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

    describe "normalizer.strict_https" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_https).to eq(false)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to true" do
          expect(Pakyow.config.normalizer.strict_https).to eq(true)
        end
      end
    end

    describe "normalizer.require_https" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.require_https).to eq(true)
      end
    end

    describe "normalizer.allowed_http_hosts" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.allowed_http_hosts).to eq(["localhost"])
      end
    end

    describe "commands.paths" do
      it "has a default value" do
        expect(Pakyow.config.commands.paths).to eq(["./commands", File.expand_path("../../../../lib/pakyow/commands", __FILE__)])
      end
    end

    describe "redis.connection.url" do
      before do
        @original_redis_url = ENV["REDIS_URL"]
        ENV.delete("REDIS_URL")
      end

      after do
        ENV["REDIS_URL"] = @original_redis_url
      end

      it "has a default value" do
        expect(Pakyow.config.redis.connection.url).to eq("redis://127.0.0.1:6379")
      end

      context "REDIS_URL is set" do
        before do
          ENV["REDIS_URL"] = "worked"
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

    describe "cookies.domain" do
      it "has a default value" do
        expect(Pakyow.config.cookies.domain).to be(nil)
      end
    end

    describe "cookies.path" do
      it "has a default value" do
        expect(Pakyow.config.cookies.path).to eq("/")
      end
    end

    describe "cookies.max_age" do
      it "has a default value" do
        expect(Pakyow.config.cookies.max_age).to be(nil)
      end
    end

    describe "cookies.expires" do
      it "has a default value" do
        expect(Pakyow.config.cookies.expires).to be(nil)
      end
    end

    describe "cookies.secure" do
      it "has a default value" do
        expect(Pakyow.config.cookies.secure).to be(nil)
      end
    end

    describe "cookies.http_only" do
      it "has a default value" do
        expect(Pakyow.config.cookies.http_only).to be(nil)
      end
    end

    describe "cookies.same_site" do
      it "has a default value" do
        expect(Pakyow.config.cookies.same_site).to be(nil)
      end
    end

    describe "deprecator.reporter" do
      it "defaults to :log" do
        expect(Pakyow.config.deprecator.reporter).to eq(:log)
      end

      context "in test" do
        before do
          Pakyow.configure!(:test)
        end

        it "defaults to :warn" do
          expect(Pakyow.config.deprecator.reporter).to eq(:warn)
        end
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to :null" do
          expect(Pakyow.config.deprecator.reporter).to eq(:null)
        end
      end
    end
  end
end
