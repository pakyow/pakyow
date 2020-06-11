# frozen_string_literal: true

generator :project, :example, extends: :project do
  source_path File.expand_path("../../../generatable/project/example", __FILE__)
end
