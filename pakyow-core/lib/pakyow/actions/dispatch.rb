# frozen_string_literal: true

require "pakyow/support/deprecatable"

module Pakyow
  module Actions
    # @deprecated
    class Dispatch
      extend Support::Deprecatable
      deprecate

      def call(connection)
        Pakyow.apps.each do |app|
          if connection.path.start_with?(app.mount_path)
            app.call(connection)
          end
        end
      end
    end
  end
end
