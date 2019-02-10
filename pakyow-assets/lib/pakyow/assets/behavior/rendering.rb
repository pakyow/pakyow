# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          before :render do
            if head = @presenter.view.head
              packs.each do |pack|
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

        # @api private
        def packs
          (autoloaded_packs + view_packs + component_packs).uniq.each_with_object([]) { |pack_name, packs|
            if found_pack = @connection.app.state(:pack).find { |pack| pack.name == pack_name.to_sym }
              packs << found_pack
            end
          }
        end

        # @api private
        def autoloaded_packs
          @connection.app.config.assets.packs.autoload
        end

        # @api private
        def view_packs
          @presenter.view.info(:packs).to_a
        end

        # @api private
        def component_packs
          @presenter.view.object.each_significant_node(:component).map { |node|
            node.label(:component)
          }
        end
      end
    end
  end
end
