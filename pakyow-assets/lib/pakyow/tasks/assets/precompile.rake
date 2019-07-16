# frozen_string_literal: true

namespace :assets do
  describe "Precompile assets"
  task :precompile, [:app] do |_, args|
    require "pakyow/assets/precompiler"
    Pakyow::Assets::Precompiler.new(args[:app]).precompile!
  end
end
