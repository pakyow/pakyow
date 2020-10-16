# frozen_string_literal: true

require "bundler"
require "securerandom"

generator :project do
  def initialize(*, **options)
    @__options = options

    super
  end

  source_path File.expand_path("../../generatable/project/default", __FILE__)

  action :bundle do
    Bundler.with_original_env do
      run "bundle install --binstubs", message: "Bundling dependencies"
    end
  end

  action :generate_application do |destination_path|
    generator_namespace = self.class.object_name.parts - Pakyow.generator(:project).object_name.parts

    if (application_generator = Pakyow.generator(:application, *generator_namespace))
      application_generator.generate(destination_path, **@__options)
    end
  end

  private def generating_locally?
    local_pakyow = Gem::Specification.sort_by { |g| [g.name.downcase, g.version] }.group_by(&:name).detect { |k, _| k == "pakyow" }
    !local_pakyow || local_pakyow.last.last.version < Gem::Version.new(Pakyow::VERSION)
  end

  private def generate_secret
    SecureRandom.hex(64)
  end
end
