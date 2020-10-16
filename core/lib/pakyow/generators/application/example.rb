# frozen_string_literal: true

generator :application, :example, extends: :application do
  source_path File.expand_path("../../../generatable/application/example", __FILE__)
end
