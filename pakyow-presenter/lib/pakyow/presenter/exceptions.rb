# frozen_string_literal: true

module Pakyow
  module Presenter
    class FrontMatterParsingError < Error; end

    class MissingPage < Error
      def message
        <<~MESSAGE
        Pakyow could not find a page to render for `#{@context}`.

        To resolve this error, create a matching template at this path:

            frontend/pages#{@context}.html
        MESSAGE
      end
    end

    class ImplicitRenderingError < MissingPage
      def name
        "Missing page"
      end

      def message
        <<~MESSAGE
        #{super}

        If you don't intend to render a view, create a route to receive requests
        to this path. Something like this:

            get "#{@context}" do
              # your code here
            end

        Controllers are located in `backend/controllers`.
        MESSAGE
      end
    end

    class MissingLayout < Error
      def message
        <<~MESSAGE
        Pakyow could not find a layout named `#{@context}`.

        To resolve this error, create a matching template at this path:

            frontend/layouts/#{@context}.html
        MESSAGE
      end
    end
  end
end
