# frozen_string_literal: true

module Pakyow
  module Presenter
    # Parses front matter from text files.
    #
    # @api private
    module FrontMatterParser
      MATTER_MATCHER = /\A---\s*\n(.*?\n?)^---\s*$\n?/m

      # Parses HTML and returns a hash of front matter info
      #
      def self.parse(html_string, _file = nil)
        match = html_string.match(MATTER_MATCHER)
        return {} unless match

        begin
          YAML.load(match.captures[0]).to_h
        rescue Psych::SyntaxError => error
          raise FrontMatterParsingError.build(error, context: match.captures[0])
        end
      end

      # Returns HTML with front matter removed
      #
      def self.scrub(html_string)
        html_string.gsub(MATTER_MATCHER, "")
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
