# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Presenter
    class FrontMatterParsingError < Error; end

    class UnknownPage < Error
      def message
        <<~MESSAGE
        Pakyow couldn't render a view for `#{@context}`. Try creating a view template for this path:

            ./frontend/pages#{@context}.html

          * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        MESSAGE
      end

      def url
        ""
      end
    end

    class ImplicitRenderingError < UnknownPage
      def name
        "Unknown page"
      end

      def message
        if Pakyow.env?(:prototype)
          super
        else
          <<~MESSAGE
          #{super}

          If you want to call backend code instead, create a controller endpoint that handles this request:

              get "#{@context}" do
                # your code here
              end

            * [Learn about controllers &rarr;](https://pakyow.com/docs/routing/)
          MESSAGE
        end
      end
    end

    class UnknownLayout < Error
      def message
        <<~MESSAGE
        Pakyow couldn't find a layout named `#{@context}`. Try creating a view template for it here:

            frontend/layouts/#{@context}.html
        MESSAGE
      end
    end
  end
end
