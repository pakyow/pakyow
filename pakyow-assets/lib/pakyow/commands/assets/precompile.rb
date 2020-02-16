# frozen_string_literal: true

command :assets, :precompile do
  describe "Precompile assets"
  required :app

  action do
    require "pakyow/assets/precompiler"

    Pakyow::Assets::Precompiler.new(@app).precompile!
  end
end
