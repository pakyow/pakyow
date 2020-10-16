# frozen_string_literal: true

module Pakyow
  module Reflection
    module Builders
      class Base
        def initialize(app, scopes)
          @app, @scopes = app, scopes
        end
      end
    end
  end
end
