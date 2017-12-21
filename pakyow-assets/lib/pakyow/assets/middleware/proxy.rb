# frozen_string_literal: true

module Pakyow
  module Assets
    class AssetProxy < Rack::Proxy
      def rewrite_env(env)
        # TODO: pull this from a config option
        env["HTTP_HOST"] = "localhost:3001"
        env["SCRIPT_NAME"] = ""
        env
      end
    end
  end
end
