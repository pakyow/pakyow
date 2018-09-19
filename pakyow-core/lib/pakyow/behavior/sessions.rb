# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Sessions.
    #
    # = Config Options
    #
    # - +config.session.enabled+ determines whether sessions are enabled for the
    #   application. Default is +true+.
    #
    # - +config.session.key+ defines the name of the key that holds the session
    #   object. Default is +{app.name}.session+.
    #
    # - +config.session.secret+ defines the value used to verify that the session
    #   has not been tampered with. Default is the value of the +SESSION_SECRET+
    #   environment variable.
    #
    # - +config.session.old_secret+ defines the old session secret, which is
    #   used to rotate session secrets in a graceful manner.
    #
    # - +config.session.expiry+ sets when sessions should expire (in seconds).
    #
    # - +config.session.path+ defines the path for the session cookie.
    #
    # - +config.session.domain+ defines the domain for the session cookie.
    #
    # - +config.session.options+ contains options passed to the session store.
    #
    # - +config.session.object+ defines the object used to store sessions. Default
    #   is +Rack::Session::Cookie+.
    module Sessions
      extend Support::Extension

      apply_extension do
        configurable :session do
          setting :enabled, true

          setting :key do
            "#{config.name}.session"
          end

          setting :secret do
            ENV["SESSION_SECRET"]
          end

          setting :object, Rack::Session::Cookie
          setting :old_secret
          setting :expiry
          setting :path
          setting :domain
        end

        # Loads and configures the session middleware.
        #
        after :configure do
          if config.session.enabled
            options = {
              key: config.session.key,
              secret: config.session.secret
            }

            # set expiry if set
            if expiry = config.session.expiry
              options[:expire_after] = expiry
            end

            # set optional options if available
            %i(domain path old_secret).each do |option|
              if value = config.session.send(option)
                options[option] = value
              end
            end

            builder.use config.session.object, options
          end
        end
      end
    end
  end
end
