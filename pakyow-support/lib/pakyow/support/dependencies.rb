# frozen_string_literal: true

module Pakyow
  module Support
    # @api private
    module Dependencies
      extend self

      def self.bundler_gem_path
        @bundler_gem_path ||= Bundler.bundle_path.to_s + "/bundler/gems"
      end

      def self.local_framework_path
        @local_framework_path ||= File.expand_path("../../../../../", __FILE__)
      end

      def self.ruby_gem_path
        @ruby_gem_path ||= File.join(Gem.dir, "/gems")
      end

      def self.regex_bundler
        @regex_bundler ||= /^#{Dependencies.bundler_gem_path}\//
      end

      def self.regex_local_framework
        @regex_local_framework ||= /^#{Dependencies.local_framework_path}\//
      end

      def self.regex_pakyow_lib
        @regex_pakyow_lib ||= /^#{Pakyow.config.lib}\//
      end

      def self.regex_pakyow_root
        @regex_pakyow_root ||= /^#{Pakyow.config.root}\//
      end

      def self.regex_ruby_gem
        @regex_ruby_gem ||= /^#{Dependencies.ruby_gem_path}\//
      end

      def self.regex_ruby
        @regex_ruby ||= /^#{RbConfig::CONFIG["libdir"]}\//
      end

      def strip_path_prefix(line)
        if line.start_with?(Pakyow.config.root)
          line.gsub(Dependencies.regex_pakyow_root, "")
        elsif line.start_with?(Pakyow.config.lib)
          line.gsub(Dependencies.regex_pakyow_lib, "")
        elsif line.start_with?(Dependencies.ruby_gem_path)
          line.gsub(Dependencies.regex_ruby_gem, "")
        elsif line.start_with?(Dependencies.bundler_gem_path)
          line.gsub(Dependencies.regex_bundler, "")
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          line.gsub(Dependencies.regex_ruby, "")
        elsif line.start_with?(Dependencies.local_framework_path)
          line.gsub(Dependencies.regex_local_framework, "")
        else
          line
        end
      end

      def library_name(line)
        case library_type(line)
        when :gem
          strip_path_prefix(line).split("/")[0].split("-")[0..-2].join("-")
        when :bundler
          strip_path_prefix(line).split("/")[1]
        when :ruby
          "ruby"
        when :pakyow
          strip_path_prefix(line).split("/")[0]
        when :lib
          strip_path_prefix(line).split("/")[1]
        else
          nil
        end
      end

      def library_type(line)
        if line.start_with?(Dependencies.ruby_gem_path)
          :gem
        elsif line.start_with?(Dependencies.bundler_gem_path)
          :bundler
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          :ruby
        elsif line.start_with?(Dependencies.local_framework_path)
          :pakyow
        elsif line.start_with?(Pakyow.config.lib)
          :lib
        else
          nil
        end
      end
    end
  end
end
