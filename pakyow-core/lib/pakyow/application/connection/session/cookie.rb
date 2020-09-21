# frozen_string_literal: true

require "base64"

require "pakyow/support/indifferentize"
require "pakyow/support/message_verifier"

require_relative "base"

module Pakyow
  class Application
    class Connection
      module Session
        class Cookie < Base
          def initialize(connection, options)
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
            connection.update_request_cookie(options.name, dup)
          end

          def to_s
            Base64.urlsafe_encode64(
              Pakyow.verifier.sign(
                Marshal.dump(to_h)
              )
            )
          end

          private

          def deserialize(connection, options)
            if (value = connection.cookies[options.name])
              Support::IndifferentHash.deep(
                Marshal.load(
                  Pakyow.verifier.verify(
                    Base64.urlsafe_decode64(value)
                  )
                )
              )
            else
              Support::IndifferentHash.new
            end
          rescue
            Support::IndifferentHash.new
          end
        end
      end
    end
  end
end
