# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Views
        extend Support::Extension

        apply_extension do
          after :initialize do
            state(:templates).each do |template_store|
              build_layout_packs(template_store)
              build_page_packs(template_store)
            end
          end
        end

        def build_layout_packs(template_store)
          template_store.layouts.each do |layout_name, layout|
            layout_pack = Pack.new(:"layouts/#{layout_name}", config.assets)
            register_pack_with_view(layout_pack, layout)

            Pathname.glob(File.join(template_store.layouts_path, "#{layout_name}.*")) do |potential_asset_path|
              next if template_store.template?(potential_asset_path)
              layout_pack << Asset.new_from_path(
                potential_asset_path,
                config: config.assets,
                related: state(:asset)
              )
            end

            self.pack << layout_pack.finalize
          end
        end

        def build_page_packs(template_store)
          template_store.paths.each do |template_path|
            template_info = template_store.info(template_path)

            page_pack = Pack.new(:"#{template_info[:page].logical_path[1..-1]}", config.assets)
            register_pack_with_view(page_pack, template_info[:page])

            # Find all partials used by the page.
            #
            partials = template_info[:page].container_views.each_with_object([]) { |page_container, page_container_partials|
              page_container_partials.concat(page_container.find_partials(template_info[:partials]))
            } + template_info[:layout].find_partials(template_info[:partials])

            # Include assets for partials used by the page into the page pack.
            #
            partials.each do |partial_name|
              if partial = template_info[:partials][partial_name]
                Pathname.glob(File.join(config.presenter.path, "#{partial.logical_path}.*")) do |potential_asset_path|
                  next if template_store.template?(potential_asset_path)
                  page_pack << Asset.new_from_path(
                    potential_asset_path,
                    config: config.assets,
                    related: state(:asset)
                  )
                end
              end
            end

            # Include assets defined for the page itself.
            #
            Pathname.glob(File.join(template_info[:page].path.dirname, "#{template_info[:page].path.basename(template_info[:page].path.extname)}.*")) do |potential_asset_path|
              next if template_store.template?(potential_asset_path)
              page_pack << Asset.new_from_path(
                potential_asset_path,
                config: config.assets,
                related: state(:asset)
              )
            end

            self.pack << page_pack.finalize
          end
        end

        def register_pack_with_view(pack, view)
          unless view.info(:packs)
            view.add_info("packs" => [])
          end

          view.info(:packs) << pack.name
        end
      end
    end
  end
end
