# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    # @api private
    module Renderable
      extend Support::Extension

      prepend_methods do
        def initialize(*args)
          @rendered = false
          super
        end
      end

      def rendered
        @rendered = true
        halt
      end

      def rendered?
        @rendered == true
      end
    end
  end
end
