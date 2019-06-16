# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Versions
        extend Support::Extension

        apply_extension do
          unless ancestors.include?(Plugin)
            # Copy global versioning logic from plugin presenters.
            #
            after "load.plugins" do
              presenters = [isolated(:Presenter)].concat(state(:presenter))

              plugs.each do |plug|
                plug.isolated(:Presenter).__versioning_logic.each_pair do |version, logic_arr|
                  logic_arr.each do |logic|
                    presenters.each do |presenter|
                      prefix = if plug.class.__object_name.name == :default
                        plug.class.plugin_name
                      else
                        "#{plug.class.plugin_name}(#{plug.class.__object_name.name})"
                      end

                      presenter.version :"#{prefix}.#{version}" do |object|
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
