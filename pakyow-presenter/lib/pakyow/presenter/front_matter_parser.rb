module Pakyow
  module Presenter
    # Module for parsing front matter from HTML
    # @api private
    module FrontMatterParser

      MATTER_MATCHER = /\A---\s*\n(.*?\n?)^---\s*$\n?/m

      # Parses HTML and returns a hash of front matter info
      #
      def self.parse(html_string)
        match = html_string.match(MATTER_MATCHER)
        return {} unless match

        begin
          info = YAML.load(match.captures[0])
        rescue Exception => e
          raise ::SyntaxError.new "Inavlid front matter YAML...\n\n #{match.captures[0]}"
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
