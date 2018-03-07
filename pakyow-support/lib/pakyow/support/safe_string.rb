# frozen_string_literal: true

require "cgi"

module Pakyow
  module Support
    class SafeString < String; end

    # Helper methods for ensuring string safety.
    #
    module SafeStringHelpers
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
      def safe(string)
        SafeString.new(string)
      end

      # Escapes html characters in the string.
      #
      def html_escape(string)
        safe(CGI.escape_html(string))
      end

      # Strips html tags from the string.
      #
      def strip_tags(string)
        safe(string.to_s.gsub(/<[^>]*>/ui, ""))
      end

      # Strips html tags from the string, except for tags specified.
      #
      def sanitize(string, tags: [])
        return strip_tags(string) if tags.empty?
        safe(string.gsub(/((?!<((\/)?#{tags.join("|")}))<[^>]*>)/i, ""))
      end
    end
  end
end
