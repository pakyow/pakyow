# frozen_string_literal: true

generator :project, :example, extends: :project do
  action :generate_default_project do |destination_path, **options|
    Generators::Project.new(
      ::File.expand_path("../../../generators/project/default", __FILE__)
    ).generate(destination_path, **options)
  end
end
