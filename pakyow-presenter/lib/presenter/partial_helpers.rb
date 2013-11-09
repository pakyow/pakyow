module Pakyow
  module Presenter
    module PartialHelpers
      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/

      def partials(refind = false)
        @partials = (!@partials || refind) ? find_partials : @partials
      end

      def partials_in(content)
        partials = []

        content.scan(PARTIAL_REGEX) do |m|
          partials << m[0].to_sym
        end

        return partials
      end
    end
  end
end