# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/error"

module Pakyow
  module Presenter
    class Error < Pakyow::Error
    end

    class FrontMatterParsingError < Error
    end

    class UnknownPage < Error
      using Support::Refinements::String::Normalization

      def contextual_message
        <<~MESSAGE
          Pakyow couldn't render a view for `#{String.normalize_path(@context)}`. Try creating a view template for this path:

              frontend/pages#{view_path}.html

            * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        MESSAGE
      end

      private

      def view_path
        if @context.to_s.empty? || @context.to_s == "/"
          "/index"
        else
          @context
        end
      end
    end

    class ImplicitRenderingError < UnknownPage
      def name
        "Unknown page"
      end

      def contextual_message
        if Pakyow.env?(:prototype)
          super
        else
          <<~MESSAGE
            #{super}

            If you want to call backend code instead, create a controller route that handles this request:

                get "#{@context}" do
                  # your code here
                end
          MESSAGE
        end
      end
    end
  end
end
