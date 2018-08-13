# frozen_string_literal: true

module Pakyow
  module Presenter
    module Helpers
      module Renderable
        def self.included(base)
          base.prepend Initializer
        end

        def rendered
          @rendered = true
          halt
        end

        def rendered?
          @rendered == true
        end

        module Initializer
          def initialize(*args)
            @rendered = false
            super
          end
        end
      end
    end
  end
end
