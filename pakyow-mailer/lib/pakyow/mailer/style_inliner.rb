# frozen_string_literal: true

require "css_parser"
require "oga"

module Pakyow
  module Mailer
    # Inlines styles into html content.
    #
    # @api private
    class StyleInliner
      def initialize(doc_or_html, stylesheets: [])
        @css_parser = CssParser::Parser.new.tap do |parser|
          stylesheets.each do |stylesheet|
            parser.load_string!(stylesheet.read)
          end
        end

        @doc = case doc_or_html
        when Oga::XML::Document
          doc_or_html
        when Oga::XML::Element
          doc_or_html
        else
          Oga.parse_html(doc_or_html.to_s)
        end
      end

      def inlined
        @css_parser.each_selector(:all) do |selector, declaration|
          @doc.css(selector).each do |node|
            node.set(:style, [declaration, node.get(:style).to_s].join(" "))
          end
        end

        @doc.to_xml
      end
    end
  end
end
