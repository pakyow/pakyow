# frozen_string_literal: true

module Pakyow
  module Support
    # @api private
    module Dependencies
      extend self

      LOCAL_FRAMEWORK_PATH = File.expand_path("../../../../../", __FILE__)

      def strip_path_prefix(line)
        if line.start_with?(Pakyow.config.root)
          line.gsub(/^#{Pakyow.config.root}\//, "")
        elsif line.start_with?(Pakyow.config.lib)
          line.gsub(/^#{Pakyow.config.lib}\//, "")
        elsif line.start_with?(Gem.default_dir)
          line.gsub(/^#{Gem.default_dir}\/gems\//, "")
        elsif line.start_with?(Bundler.bundle_path.to_s)
          line.gsub(/^#{Bundler.bundle_path.to_s}\/gems\//, "")
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          line.gsub(/^#{RbConfig::CONFIG["libdir"]}\//, "")
        elsif line.start_with?(LOCAL_FRAMEWORK_PATH)
          line.gsub(/^#{LOCAL_FRAMEWORK_PATH}\//, "")
        else
          line
        end
      end

      def library_name(line)
        case library_type(line)
        when :gem, :bundler
          strip_path_prefix(line).split("/")[0].split("-")[0..-2].join("-")
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
        if line.start_with?(Gem.default_dir)
          :gem
        elsif line.start_with?(Bundler.bundle_path.to_s)
          :bundler
        elsif line.start_with?(RbConfig::CONFIG["libdir"])
          :ruby
        elsif line.start_with?(LOCAL_FRAMEWORK_PATH)
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
