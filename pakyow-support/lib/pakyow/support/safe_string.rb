# frozen_string_literal: true

require "cgi"

module Pakyow
  module Support
    class SafeString < String
      def initialize(*)
        super
        freeze
      end

      def to_s
        self
      end
    end

    # Helper methods for ensuring string safety.
    #
    module SafeStringHelpers
      extend self

      # Escapes the string unless it's marked as safe.
      #
      def ensure_html_safety(string)
        html_safe?(string) ? string : html_escape(string)
      end

      # Returns true if the string is marked as safe.
      #
      def html_safe?(string)
        string.is_a?(SafeString)
      end

      # Marks a string as safe.
      #
      def html_safe(string)
        html_safe?(string) ? string : SafeString.new(string)
      end

      # Escapes html characters in the string.
      #
      def html_escape(string)
        html_safe(CGI.escape_html(string.to_s))
      end

      # Strips html tags from the string.
      #
      def strip_tags(string)
        html_safe(string.to_s.gsub(/<[^>]*>/ui, ""))
      end

      # Strips html tags from the string, except for tags specified.
      #
      def sanitize(string, tags: [])
        return strip_tags(string) if tags.empty?
        html_safe(string.to_s.gsub(/((?!<((\/)?#{tags.join("|")}))<[^>]*>)/i, ""))
      end
    end
  end
end
