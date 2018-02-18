# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/core/loader"

module Pakyow
  module Behavior
    # Maintains known aspects and loads them.
    #
    module Aspects
      extend Support::Extension

      apply_extension do
        config.app.setting :aspects, []

        after :load do
          config.app.aspects.each do |aspect|
            load_app_aspect(File.join(config.app.src, aspect.to_s), aspect)
          end
        end
      end

      class_methods do
        # Registers an app aspect by name.
        #
        def aspect(name)
          (config.app.aspects << name.to_sym).uniq!
        end
      end

      private

      def load_app_aspect(state_path, state_type, load_target = self.class)
        Dir.glob(File.join(state_path, "*.rb")) do |path|
          if config.app.dsl
            Loader.new(load_target, Support::ClassNamespace.new(config.app.name, state_type), path).call
          else
            require path
          end
        end

        Dir.glob(File.join(state_path, "*")).select { |path| File.directory?(path) }.each do |directory|
          load_app_aspect(directory, state_type, load_target)
        end
      end
    end
  end
end
