# frozen_string_literal: true

generator :project, :example, extends: :project do
  def initialize(source_path)
    @default_generator = Generators::Project.new(
      ::File.expand_path("../../../generators/project/default", __FILE__)
    )

    super
  end

  def generate(*args)
    @default_generator.generate(*args)

    super
  end
end
