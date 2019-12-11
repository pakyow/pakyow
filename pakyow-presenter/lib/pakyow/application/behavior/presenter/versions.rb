# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module Versions
          extend Support::Extension

          apply_extension do
            if ancestors.include?(Plugin)
              # Copy global versioning logic from other plugins to this plugin.
              #
              after "load" do
                presenters = [isolated(:Presenter)].concat(state(:presenter))

                parent.plugs.each do |plug|
                  plug.isolated(:Presenter).__versioning_logic.each_pair do |version, logic_arr|
                    logic_arr.each do |logic|
                      presenters.each do |presenter|
                        unless presenter.__versioning_logic.include?(version)
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
                  end
                end
              end
            else
              # Copy global versioning logic from plugin presenters.
              #
              after "load.plugins" do
                presenters = [isolated(:Presenter)].concat(state(:presenter))

                plugs.each do |plug|
                  plug.isolated(:Presenter).__versioning_logic.each_pair do |version, logic_arr|
                    logic_arr.each do |logic|
                      presenters.each do |presenter|
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
                end
              end
            end
          end
        end
      end
    end
  end
end
