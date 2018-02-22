# frozen_string_literal: true

module Pakyow
  module Commands
    module Helpers
      def find_app(name)
        if name
          Pakyow.find_app(name) || (Pakyow.logger.error("Could not find an app named `#{name}'"); exit)
        elsif Pakyow.apps.count == 1
          Pakyow.apps.first
        else
          Pakyow.logger.error "Multiple apps are present; please provide an app name (via the --app option)"
          exit
        end
      end
    end
  end
end
