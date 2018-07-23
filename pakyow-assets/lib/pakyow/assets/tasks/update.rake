# frozen_string_literal: true

namespace :assets do
  describe "Update external assets"
  argument :asset, "desc", required: false
  task :update, [:app, :asset] do |_, args|
    require "pakyow/assets/external"
    args[:app].config.assets.externals.scripts.each do |external_script|
      external_script.fetch!
    end
  end
end
