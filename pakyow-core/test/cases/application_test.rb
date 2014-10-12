require 'support/helper'

module Pakyow
  module Test
    class ApplicationTest < Minitest::Test
      def test_application_path_is_set_when_inherited
        assert(Pakyow::Config::App.path.include?(app_test_path))
      end

      def test_application_runs
        app(true).run(:test)
        assert_equal(true, app.running?)
      end

      def test_is_not_staged_when_running
        app(true).run(:test)
        assert_same(false, app.staged?)
      end

      def test_application_does_not_run_when_staged
        app(true).stage(:test)
        assert_equal false, app.running?
      end

      def test_detect_staged_application
        app(true).stage(:test)
        assert_equal(true, app.staged?)
      end

      def test_base_config_is_returned
        assert_equal(Pakyow::Config::Base, app(true).config)
      end

      def test_env_is_set_when_initialized
        envs = [:test, :foo]
        app(true).stage(*envs)
        assert_equal(envs.first, Pakyow.app.env)
      end

      def test_app_is_set_when_initialized
        app(true)
        assert_nil(Pakyow.app)
        app(true).run(:test)
        assert_equal(Pakyow::App, Pakyow.app.class)
      end

      def test_global_configure_block_is_executed
        Pakyow::App.stage(:test)
        assert_equal(true, $global_config_was_executed)
      end

      def test_env_config_supercedes_global_config
        assert_equal(true, $env_overwrites_global_config)
      end

      def test_config_loaded_before_middleware
        app = app(true)
        
        value = nil
        app.middleware do
          value = config.app.foo
        end

        app.stage(:test)

        assert_equal :bar, value
      end

      def test_multiple_middleware_loaded
        app = app(true)

        value1 = nil
        app.middleware do
          value1 = config.app.foo
        end

        value2 = nil
        app.middleware do
          value2 = config.app.foo
        end

        app.stage(:test)

        assert_equal :bar, value1
        assert_equal :bar, value2
      end

      def test_builder_is_yielded_to_middleware
        app = app(true)

        builder = nil
        app.middleware do |o|
          builder = o
        end

        app.stage(:test)

        assert_instance_of Rack::Builder, builder
      end

      protected

      def app(do_reset = false)
        Pakyow::App.reset(do_reset)
      end

      def app_test_path
        File.join('test', 'support', 'app.rb')
      end

    end
  end
end
