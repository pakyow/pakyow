# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Presenter
        module Rendering
          def render(view_path = nil, as: nil, modes: [:default])
            @connection.render(view_path, as: as, modes: modes)
          end
        end
      end
    end
  end
end
