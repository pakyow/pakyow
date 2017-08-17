module Pakyow
  module Presenter
    # Module for parsing front matter from HTML
    # @api private
    module FrontMatterParser

      MATTER_MATCHER = /\A---\s*\n(.*?\n?)^---\s*$\n?/m

      # Parses HTML and returns a hash of front matter info
      #
      def self.parse(html_string, file = nil)
        match = html_string.match(MATTER_MATCHER)
        return {} unless match

        begin
          info = YAML.load(match.captures[0])
        rescue Psych::SyntaxError => e
          message = "Could not parse front matter"
          message << " for file #{file}" if file
          message << "\n\n#{e.problem} at line #{e.line} column #{e.column}\n\n"
          message << match.captures[0]
          raise ::SyntaxError.new message
        end

        info = {} if !info || !info.is_a?(Hash)
        Hash.symbolize(info)
      end

      # Returns HTML with front matter removed
      #
      def self.scrub(html_string)
        html_string.gsub(MATTER_MATCHER, '')
      end

      # Parses HTML and returns:
      # - a hash of front matter info
      # - the HTML with front matter removed
      #
      def self.parse_and_scrub(html_string)
        return parse(html_string), scrub(html_string)
      end
    end
  end
end
