# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/loader"

module Pakyow
  module Behavior
    # Maintains known aspects and loads them.
    #
    module Aspects
      extend Support::Extension

      apply_extension do
        setting :aspects, []

        after :load do
          config.aspects.each do |aspect|
            load_aspect(aspect)
          end
        end
      end

      class_methods do
        # Registers an app aspect by name.
        #
        def aspect(name)
          (config.aspects << name.to_sym).uniq!
        end
      end

      private

      def load_aspect(aspect, path: File.join(config.src, aspect.to_s), target: self.class)
        Dir.glob(File.join(path, "*.rb")) do |file_path|
          Loader.new(file_path).call(target)
        end

        Dir.glob(File.join(path, "*")).select { |sub_path| File.directory?(sub_path) }.each do |directory|
          load_aspect(aspect, path: directory, target: target)
        end
      end
    end
  end
end
