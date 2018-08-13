# frozen_string_literal: true

namespace :assets do
  describe "Update external assets"
  argument :asset, "The asset to update", required: false
  task :update, [:app, :asset] do |_, args|
    require "pakyow/assets/external"

    scripts = if args.key?(:asset)
      [args[:app].config.assets.externals.scripts.find { |script|
        script.name == args[:asset].to_sym
      } || raise("#{Pakyow::Support::CLI.style.blue(args[:asset])} is not an external script")]
    else
      args[:app].config.assets.externals.scripts
    end

    scripts.each(&:fetch!)
  end
end
