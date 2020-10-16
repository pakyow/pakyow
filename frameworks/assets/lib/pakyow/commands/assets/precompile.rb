# frozen_string_literal: true

command :assets, :precompile, prelaunch: :build do
  describe "Precompile assets"
  required :app

  action do
    require_relative "../../assets/precompiler"

    if @app.class.includes_framework?(:assets)
      Pakyow::Assets::Precompiler.new(@app).precompile!
    end
  end
end
