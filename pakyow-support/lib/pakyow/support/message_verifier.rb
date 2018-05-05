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
    end
  end
end
