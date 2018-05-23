# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          before :render do
            next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

            packs.each do |pack|
              if pack.javascripts?
                head.append("<script src=\"#{pack.public_path}.js\"></script>\n")
              end

              if pack.stylesheets?
                head.append("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{pack.public_path}.css\">\n")
              end
            end
          end
        end

        # @api private
        def packs
          (autoloaded_packs + view_packs).uniq.each_with_object([]) { |pack_name, packs|
            if pack = @connection.app.state_for(:pack).find { |pack| pack.name == pack_name.to_sym }
              packs << pack
            end
          }
        end

        # @api private
        def autoloaded_packs
          @connection.app.config.assets.autoloaded_packs
        end

        # @api private
        def view_packs
          @presenter.view.info(:packs).to_a
        end
      end
    end
  end
end
