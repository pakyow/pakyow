# frozen_string_literal: true

require "pakyow/support/indifferentize"

require "pakyow/app/connection/session/abstract"

module Pakyow
  class App
    class Connection
      module Session
        class Cookie < Abstract
          def initialize(connection, options)
            if (cookie = connection.cookies[options.name]) && !cookie.is_a?(String)
              super(connection, options, Support::IndifferentHash.new(cookie[:value].to_h))
              connection.cookies[options.name][:value] = self
            else
              super(connection, options, deserialize(connection, options))
              connection.cookies[options.name] = Support::IndifferentHash.new(
                domain: options.domain,
                path: options.path,
                max_age: options.max_age,
                expires: options.expires,
                secure: options.secure,
                http_only: options.http_only,
                same_site: options.same_site,
                value: self
              )

              # Update the original cookie value so we can compare for changes.
              #
              connection.update_request_cookie(options.name, self)
            end
          end

          def to_s
            Marshal.dump(to_h)
          end

          private

          def deserialize(connection, options)
            if value = connection.cookies[options.name]
              Support::IndifferentHash.new(Marshal.load(value))
            else
              Support::IndifferentHash.new
            end
          end
        end
      end
    end
  end
end
