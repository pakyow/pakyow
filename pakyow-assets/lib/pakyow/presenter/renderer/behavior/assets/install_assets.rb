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
                  (app.top.class.packs_for_view(view) + app.class.packs_for_view(view)).uniq { |pack|
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
