# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        module Assets
          module InstallAssets
            extend Support::Extension

            apply_extension do
              build do |view, app:|
                if head = view.head
                  packs = app.packs_for_view(view)

                  if app.is_a?(Plugin)
                    packs = app.parent.packs_for_view(view).concat(packs)
                  end

                  packs.uniq { |pack|
                    pack.public_path
                  }.each do |pack|
                    if pack.javascripts?
                      head.object.append_html("<script src=\"#{File.join(app.top.config.assets.host, pack.public_path)}.js\"></script>\n")
                    end

                    if pack.stylesheets?
                      head.object.append_html("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{File.join(app.top.config.assets.host, pack.public_path)}.css\">\n")
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
end
