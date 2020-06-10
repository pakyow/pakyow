# frozen_string_literal: true

require "bundler"
require "securerandom"

generator :project do
  action :bundle do
    Bundler.with_original_env do
      run "bundle install --binstubs", message: "Bundling dependencies"
    end
  end

  action :update_assets do
    Bundler.with_original_env do
      run "bundle exec pakyow assets:update", message: "Updating external assets"
    end
  end

  # TODO: Can this be private?
  #
  private def generating_locally?
    local_pakyow = Gem::Specification.sort_by { |g| [g.name.downcase, g.version] }.group_by(&:name).detect { |k, _| k == "pakyow" }
    !local_pakyow || local_pakyow.last.last.version < Gem::Version.new(Pakyow::VERSION)
  end

  # TODO: Can this be private?
  #
  private def generate_secret
    SecureRandom.hex(64)
  end
end
