# frozen_string_literal: true

module Pakyow
  class App
    class Connection
      module Helpers
        module Form
          def form
            get(:__form)
          end
        end
      end
    end
  end
end
