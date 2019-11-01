# frozen_string_literal: true

require "pakyow/support/system"

module Pakyow
  module Support
    # TODO: Refactor this into a Pakyow::Backtrace object that's responsible for providing a clean
    # backtrace and understands things like where the backtrace originated from.
    #
    # @api private
    module Dependencies
      def strip_path_prefix(line)
        if line.start_with?(Pakyow.config.root)
          line.gsub(__regex_pakyow_root, "")
        elsif line.start_with?(Pakyow.config.lib)
          line.gsub(__regex_pakyow_lib, "")
        elsif line.start_with?(System.ruby_gem_path_string)
          line.gsub(__regex_ruby_gem, "")
        elsif line.start_with?(System.bundler_gem_path_string)
          line.gsub(__regex_bundler, "")
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          line.gsub(__regex_ruby, "")
        elsif line.start_with?(System.local_framework_path_string)
          line.gsub(__regex_local_framework, "")
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
        if line.start_with?(System.ruby_gem_path_string)
          :gem
        elsif line.start_with?(System.bundler_gem_path_string)
          :bundler
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          :ruby
        elsif line.start_with?(System.local_framework_path_string)
          :pakyow
        elsif line.start_with?(Pakyow.config.lib)
          :lib
        else
          nil
        end
      end

      module_function :strip_path_prefix, :library_name, :library_type

      # These regexes are built eagerly because they depend on state that may not be available at runtime.

      # @api private
      def self.__regex_bundler
        @__regex_bundler ||= /^#{System.bundler_gem_path}\//
      end

      # @api private
      def self.__regex_local_framework
        @__regex_local_framework ||= /^#{System.local_framework_path}\//
      end

      # @api private
      def self.__regex_pakyow_lib
        @__regex_pakyow_lib ||= /^#{Pakyow.config.lib}\//
      end

      # @api private
      def self.__regex_pakyow_root
        @__regex_pakyow_root ||= /^#{Pakyow.config.root}\//
      end

      # @api private
      def self.__regex_ruby_gem
        @__regex_ruby_gem ||= /^#{System.ruby_gem_path}\//
      end

      # @api private
      def self.__regex_ruby
        @__regex_ruby ||= /^#{RbConfig::CONFIG["libdir"]}\//
      end
    end
  end
end
