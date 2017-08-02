module Pakyow
  module Support
    class SafeString < String; end

    module SafeStringHelpers
      def ensure_html_safety(string)
        html_safe?(string) ? string : html_escape(string)
      end

      def html_safe?(string)
        string.is_a?(SafeString)
      end

      def safe(string)
        SafeString.new(string)
      end

      def html_escape(string)
        safe(CGI.escape_html(string))
      end

      def strip_tags(string)
        safe(string.gsub(/<[^>]*>/ui, ""))
      end

      def sanitize(string, tags: [])
        return strip_tags(string) if tags.empty?
        safe(string.gsub(/((?!<((\/)?#{tags.join("|")}))<[^>]*>)/i, ""))
      end
    end
  end
end
