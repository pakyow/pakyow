# frozen_string_literal: true

require "base64"
require "openssl"
require "securerandom"

module Pakyow
  module Support
    # Signs and verifes messages for a key.
    #
    class MessageVerifier
      attr_reader :key

      JOIN_CHARACTER = "~"

      # TODO: support configuring the digest
      # TODO: support rotations by calling `rotate` with options
      #
      def initialize(key = self.class.key)
        @key = key
      end

      # Returns a signed message.
      #
      def sign(message)
        [Base64.urlsafe_encode64(message), self.class.digest(message, key: @key)].join(JOIN_CHARACTER)
      end

      # Returns the message if the signature is valid for the key, or raises `TamperedMessage`.
      #
      def verify(signed)
        message, digest = signed.to_s.split(JOIN_CHARACTER, 2)

        begin
          message = Base64.urlsafe_decode64(message.to_s)
        rescue ArgumentError
        end

        if self.class.valid?(digest, message: message, key: @key)
          message
        else
          raise(TamperedMessage)
        end
      end

      class << self
        # Generates a random key.
        #
        def key
          SecureRandom.hex(24)
        end

        # Generates a digest for a message with a key.
        #
        def digest(message, key:)
          Base64.urlsafe_encode64(
            OpenSSL::HMAC.digest(
              OpenSSL::Digest.new("sha256"), message.to_s, key.to_s
            )
          )
        end

        # Returns true if the digest is valid for the message and key.
        #
        def valid?(digest, message:, key:)
          digest == self.digest(message, key: key)
        end
      end

      class TamperedMessage < StandardError
      end
    end
  end
end
