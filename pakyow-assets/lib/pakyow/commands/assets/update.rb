# frozen_string_literal: true

command :assets, :update do
  describe "Update external assets"
  required :app

  argument :asset, "The asset to update"

  action do
    require "pakyow/assets/errors"
    require "pakyow/assets/external"

    if @asset
      @asset = @asset.to_sym

      script = @app.config.assets.externals.scripts.find { |script|
        script.name == asset
      } || raise(Pakyow::Assets::UnknownExternalAsset.new_with_message(asset: asset))

      script.fetch!
    else
      @app.config.assets.externals.scripts.each(&:fetch!)
    end
  end
end
