# frozen_string_literal: true

namespace :assets do
  desc "Precompiles assets"
  task :precompile, [:app] do |_, args|
    require "pakyow/assets/precompiler"
    Pakyow::Assets::Precompiler.new(args[:app]).precompile!
  end

  desc "Updates external assets"
  task :update, [:app] do |_, args|
    require "pakyow/assets/external"

    args[:app].config.assets.external_scripts.each do |external_script|
      external_script.fetch!
    end
  end
end
