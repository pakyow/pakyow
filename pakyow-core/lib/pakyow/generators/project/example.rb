# frozen_string_literal: true

require_relative "../../generator"
require_relative "../project"

module Pakyow
  # @api private
  module Generators
    class Project
      class Example < Generator
        def initialize(source_path)
          @default_generator = Project.new(
            ::File.expand_path("../default", __FILE__)
          )

          super
        end

        def generate(*args)
          @default_generator.generate(*args)

          super
        end
      end
    end
  end
end
