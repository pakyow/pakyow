# frozen_string_literal: true

require "pakyow/assets"
require "pakyow/core/framework"
require "pakyow/js/source"

module Pakyow
  module JS
    class Framework < Pakyow::Framework(:js)
      def boot
        app.class_eval do
          after :configure do
            config.assets.autoloaded_packs << :pakyow
            config.assets.packs_paths << Source.pack_path
          end
        end
      end
    end
  end
end
