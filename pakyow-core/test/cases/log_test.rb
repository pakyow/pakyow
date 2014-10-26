require 'support/helper'

require 'stringio'

module Pakyow
  module Test
    class LogTest < Minitest::Test
      def setup
        Pakyow::Config.logger.colorize = false
        @text = 'foo'
      end

      def teardown
        FileUtils.rm(file) if File.exists?(file)
      end

      def test_log_to_console
        old = $stdout
        $stdout = StringIO.new
        Pakyow.configure_logger
        Pakyow.logger << @text

        assert_equal @text.strip, $stdout.string.strip

        $stdout = old
      end

      def test_log_to_file
        Pakyow::Config.logger.path = path
        Pakyow::Config.logger.auto_flush = true
        Pakyow.configure_logger
        Pakyow.logger << @text

        assert       File.exists?(file)
        assert_equal @text.strip, File.new(file).read.strip
      end

      private

      def file
        File.join(path, 'pakyow.log')
      end

      def path
        File.join(Dir.pwd, 'test')
      end
    end
  end
end
