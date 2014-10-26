require 'support/helper'

module Pakyow
  module Test
    class LoaderTest < Minitest::Test
      def setup
        @loader = Pakyow::Loader.new
        @loader.load_from_path(path)
      end

      def test_recursively_loads_files
        assert Object.const_defined?(:Reloadable)
      end

      def test_should_tell_time
        Pakyow::Config.app.auto_reload = true

        times = @loader.times.dup
        `touch #{File.join(path, 'reloadable.rb')}`
        @loader.load_from_path(path)

        assert times.first.nil?
        assert !@loader.times.first.nil?
      end

      private

      def path
        File.join(Dir.pwd, 'test', 'support', 'loader')
      end
    end

    class Pakyow::Loader
      attr_accessor :times
    end
  end
end
