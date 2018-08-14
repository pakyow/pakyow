# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      # Cookies!
      #
      # = Config Options
      #
      # - +config.cookies.path+ sets the URL path that must exist in the requested
      #   resource before sending the Cookie header. Default is +/+.
      #
      # - +config.cookies.expiry+ sets when cookies should expire, specified in
      #   seconds. Default is +60 * 60 * 24 * 7+ seconds, or 7 days.
      module Cookies
        extend Support::Extension

        apply_extension do
          configurable :cookies do
            setting :path, "/"
            setting :expiry, 60 * 60 * 24 * 7
          end
        end
      end
    end
  end
end
