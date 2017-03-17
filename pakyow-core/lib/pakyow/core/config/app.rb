require "pakyow/support/configurable"

module Pakyow
  class App
    include Support::Configurable

    settings_for :app, extendable: true do
      setting :name, "pakyow"

      setting :resources do
        @resources ||= {
          default: File.join(config.app.root, "public")
        }
      end

      setting :src do
        File.join(config.app.root, "app", "lib")
      end

      setting :root, File.dirname("")
    end

    settings_for :router do
      setting :enabled, true

      defaults :prototype do
        setting :enabled, false
      end
    end

    settings_for :errors do
      setting :enabled, true

      defaults :production do
        setting :enabled, false
      end
    end

    settings_for :static do
      setting :enabled, true
    end

    settings_for :normalizer do
      setting :enabled, true

      setting :www
      setting :path, true
    end

    settings_for :cookies do
      setting :path, "/"

      setting :expiry do
        Time.now + 60 * 60 * 24 * 7
      end
    end

    settings_for :session do
      setting :enabled, true
      setting :object, Rack::Session::Cookie
      setting :old_secret
      setting :expiry
      setting :path
      setting :domain

      setting :opts do
        opts = {
          key: config.session.key,
          secret: config.session.secret
        }

        # set optional options if available
        %i(domain path expire_after old_secret).each do |opt|
          value = config.session.send(opt)
          opts[opt] = value if value
        end

        opts
      end

      setting :key do
        "#{config.app.name}.session"
      end

      setting :secret do
        ENV['SESSION_SECRET']
      end
    end
  end
end
