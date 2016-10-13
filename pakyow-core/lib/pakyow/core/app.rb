require "pakyow/core/helpers/configuring"
require "pakyow/core/call_context"
require "pakyow/core/helpers"
require "pakyow/core/config"
require "pakyow/core/config/app"
require "pakyow/core/loader"
require "pakyow/core/router"

require "pakyow/support/defineable"
require "pakyow/support/hookable"

module Pakyow
  # The main app object.
  #
  # @api public
  class App
    include Support::Defineable
    include Support::Hookable

    known_events :init, :configure, :load, :reload, :fork

    extend Helpers::Configuring

    class << self
      # Convenience method for accessing app configuration object.
      #
      # @api public
      def config
        Pakyow::Config
      end
    end

    def initialize(env)
      Pakyow.app = self

      @loader = Loader.new

      hook_around :init do
        load_app
      end
    end

    # @api private
    def call(env)
      # TODO: I think I like duping self more than I do this
      CallContext.new(env).process.finish
    end

    protected

    def load_app
      hook_around :load do
        @loader.load_from_path(Pakyow::Config.app.src_dir)
        load_routes
      end
    end

    def load_routes
      return if Pakyow::Config.app.ignore_routes

      Router.instance.reset
      self.class.routes.each_pair do |set_name, block|
        Router.instance.set(set_name, &block)
      end
    end
  end
end
