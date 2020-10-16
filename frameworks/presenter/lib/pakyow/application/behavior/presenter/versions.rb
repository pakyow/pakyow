# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module Versions
          extend Support::Extension

          apply_extension do
            unless ancestors.include?(Plugin)
              after "initialize.plugins" do
                presenter_definitions = [isolated(:Presenter)].concat(presenters.each.to_a)

                plugs.each do |plug|
                  # Copy global versioning logic from plugin presenters.
                  #
                  plug.isolated(:Presenter).__versioning_logic.each_pair do |version, logic_arr|
                    logic_arr.each do |logic|
                      presenter_definitions.each do |presenter|
                        plug_namespace = plug.class.object_name.namespace.parts.last

                        prefix = if plug_namespace == :default
                          plug.class.plugin_name
                        else
                          "#{plug.class.plugin_name}(#{plug_namespace})"
                        end

                        presenter.version :"@#{prefix}.#{version}" do |object|
                          instance_exec(object, plug, &logic[:block])
                        end
                      end
                    end
                  end

                  # Copy global versioning logic from other plugins to this plugin.
                  #
                  plugin_presenter_definitions = [plug.isolated(:Presenter)].concat(plug.presenters.each.to_a)
                  plugs.each do |other_plug|
                    next if other_plug.equal?(plug)

                    other_plug.isolated(:Presenter).__versioning_logic.each_pair do |version, logic_arr|
                      logic_arr.each do |logic|
                        plugin_presenter_definitions.each do |presenter|
                          unless presenter.__versioning_logic.include?(version)
                            plug_namespace = other_plug.class.object_name.namespace.parts.last

                            prefix = if plug_namespace == :default
                              other_plug.class.plugin_name
                            else
                              "#{other_plug.class.plugin_name}(#{plug_namespace})"
                            end

                            presenter.version :"@#{prefix}.#{version}" do |object|
                              instance_exec(object, other_plug, &logic[:block])
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
      end
    end
  end
end
