# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Packs
          extend Support::Extension

          apply_extension do
            after "load", "load.assets.packs" do
              config.assets.packs.paths.each do |packs_path|
                Pathname.glob(File.join(packs_path, "*.*")).group_by { |path|
                  File.join(File.dirname(path), File.basename(path, File.extname(path)))
                }.to_a.sort { |pack_a, pack_b|
                  pack_b[1] <=> pack_a[1]
                }.uniq { |pack_path, _|
                  accessible_pack_path(pack_path)
                }.map { |pack_path, pack_asset_paths|
                  [accessible_pack_path(pack_path), pack_asset_paths]
                }.reverse.each do |pack_path, pack_asset_paths|
                  asset_pack = isolated(:Pack).new(File.basename(pack_path).to_sym, config.assets)

                  pack_asset_paths.each do |pack_asset_path|
                    if config.assets.extensions.include?(File.extname(pack_asset_path))
                      asset_pack << isolated(:Asset).new_from_path(
                        pack_asset_path,
                        config: config.assets,
                        related: assets
                      )
                    end
                  end

                  packs << asset_pack.finalize
                end
              end

              templates.each do |template_store|
                build_layout_packs(template_store)
                build_page_packs(template_store)
              end
            end
          end

          class_methods do
            def packs_for_view(view)
              (autoloaded_packs + view_packs(view) + component_packs(view)).uniq.each_with_object([]) { |pack_name, packs_for_view|
                if found_pack = packs.each.find { |pack| pack.name == pack_name.to_sym }
                  packs_for_view << found_pack
                end
              }
            end

            private

            def accessible_pack_path(pack_path)
              pack_path_parts = pack_path.split("/")
              pack_path_parts[-1] = if pack_path_parts[-1].include?("__")
                pack_path_parts[-1].split("__", 2)[1]
              elsif pack_path_parts[-1].include?("@")
                pack_path_parts[-1].split("@", 2)[0]
              else
                pack_path_parts[-1]
              end

              pack_path_parts.join("/")
            end

            def autoloaded_packs
              config.assets.packs.autoload
            end

            def view_packs(view)
              view.info(:packs).to_a
            end

            def component_packs(view)
              view.object.each_significant_node(:component, descend: true).flat_map { |node|
                node.label(:components).map { |component|
                  component[:name]
                }
              }
            end

            def build_layout_packs(template_store)
              template_store.layouts.each do |layout_name, layout|
                layout_pack = isolated(:Pack).new(:"layouts/#{layout_name}", config.assets)
                register_pack_with_view(layout_pack, layout)

                template_store.layout_paths.each do |layouts_path|
                  Pathname.glob(File.join(layouts_path, "#{layout_name}.*")) do |potential_asset_path|
                    next if template_store.template?(potential_asset_path)

                    layout_pack << isolated(:Asset).new_from_path(
                      potential_asset_path,
                      config: config.assets,
                      related: assets.each.to_a
                    )
                  end
                end

                packs << layout_pack.finalize
              end
            end

            def build_page_packs(template_store)
              template_store.paths.each do |view_path|
                template_info = template_store.info(view_path)

                page_pack = isolated(:Pack).new(:"#{template_info[:page].logical_path[1..-1]}", config.assets)
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

                      assets_config = if ancestors.include?(Plugin) && potential_asset_path.to_s.start_with?(parent.config.presenter.path)
                        parent.config.assets
                      else
                        config.assets
                      end

                      page_pack << isolated(:Asset).new_from_path(
                        potential_asset_path,
                        config: assets_config,
                        related: assets.each.to_a
                      )
                    end
                  end
                end

                # Include assets defined for the page itself.
                #
                Pathname.glob(File.join(template_info[:page].path.dirname, "#{template_info[:page].path.basename(template_info[:page].path.extname)}.*")) do |potential_asset_path|
                  next if template_store.template?(potential_asset_path)

                  assets_config = if ancestors.include?(Plugin) && potential_asset_path.to_s.start_with?(parent.config.presenter.path)
                    parent.config.assets
                  else
                    config.assets
                  end

                  page_pack << isolated(:Asset).new_from_path(
                    potential_asset_path,
                    config: assets_config,
                    related: assets.each.to_a
                  )
                end

                self.packs << page_pack.finalize
              end
            end

            def register_pack_with_view(pack, view)
              unless view.info(:packs)
                view.add_info(packs: [])
              end

              view.info(:packs) << pack.name
            end
          end
        end
      end
    end
  end
end
