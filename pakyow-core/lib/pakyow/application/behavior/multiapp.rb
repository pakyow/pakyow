# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Multiapp
        extend Support::Extension

        apply_extension do
          setting :root do
            if Pakyow.multiapp?
              File.join(Pakyow.config.multiapp_path, config.name.to_s)
            else
              Pakyow.config.root
            end
          end

          before "load" do
            next unless Pakyow.multiapp?

            config.aspects.each do |aspect|
              load_aspect(aspect, path: File.join(Pakyow.config.common_src, aspect.to_s))
            end
          end
        end
      end
    end
  end
end
