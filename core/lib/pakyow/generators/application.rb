# frozen_string_literal: true

require "pakyow/support/inflector"

generator :application do
  required :name
  optional :path, default: "/"

  source_path File.expand_path("../../generatable/application/default", __FILE__)

  action :update_assets do
    Bundler.with_original_env do
      options = {
        message: "Updating external assets"
      }

      if Pakyow.project?
        # Guarantees that we're running from the project root when generating a nested application.
        #
        options[:from] = Pakyow.config.root
      end

      run "bundle exec pakyow assets:update -a #{name}", **options
    end
  end

  def human_name
    Pakyow::Support.inflector.humanize(name)
  end
end
