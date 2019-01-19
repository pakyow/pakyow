# frozen_string_literal: true

require "base64"
require "securerandom"

module Pakyow
  module Support
    # Helper for signing messages and verifying them later.
    #
    class MessageVerifier
      # Returns a random key.
      #
      def self.key
        SecureRandom.hex(24)
      end

      # Returns the signed message for the key.
      #
      def self.sign(message, key:)
        "#{message}:#{digest(message, key: key)}"
      end

      # Generates a digest for a message with a key.
      #
      def self.digest(message, key:)
        Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest.new("sha256"), message.to_s, key.to_s
          )
        ).strip
      end

      # Returns true if the given digest is valid for the message and key.
      #
      def self.valid?(message, digest:, key:)
        digest == self.digest(message, key: key)
      end

      # Returns true if the signed value is valid for the key, or raises `TamperedMessage`.
      #
      def self.verify(signed, key:)
        message, digest = signed.to_s.split(":", 2)
        valid?(message, digest: digest, key: key) || raise(TamperedMessage)
      end

      class TamperedMessage < StandardError
      end
    end
  end
end
