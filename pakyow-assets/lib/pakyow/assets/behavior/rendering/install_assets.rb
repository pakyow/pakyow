# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Rendering
        module InstallAssets
          extend Support::Extension

          apply_extension do
            build do |view, app:|
              if head = view.head
                packs = app.packs(view)

                if app.is_a?(Plugin)
                  packs.concat(app.parent.packs(view))
                end

                packs.uniq { |pack|
                  pack.public_path
                }.each do |pack|
                  if pack.javascripts?
                    head.object.append_html("<script src=\"#{pack.public_path}.js\"></script>\n")
                  end

                  if pack.stylesheets?
                    head.object.append_html("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{pack.public_path}.css\">\n")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
