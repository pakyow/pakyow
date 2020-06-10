# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../generator"
require_relative "../loader"

module Pakyow
  module Behavior
    module Generators
      extend Support::Extension

      apply_extension do
        configurable :generators do
          setting :paths, ["./generators", File.expand_path("../../generators", __FILE__)]
        end

        definable :generator, Generator

        after "load", "load.generators" do
          load_generators
        end

        # @api private
        def load_generators
          config.generators.paths.uniq.each_with_object(generators) do |generators_path, generators|
            Loader.load_path(File.expand_path(generators_path), target: Pakyow)
          end
        end
      end
    end
  end
end
