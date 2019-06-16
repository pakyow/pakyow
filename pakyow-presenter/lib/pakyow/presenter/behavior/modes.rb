# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Modes
        class ModeCallContext
          def initialize(connection)
            @connection = connection
          end
        end

        extend Support::Extension

        attr_accessor :__ui_modes

        def mode(name, &block)
          @__ui_modes[name.to_sym] = wrap_mode_block(block)
        end

        private def wrap_mode_block(block)
          if is_a?(Plugin)
            wrap_mode_block_for_plug(self, block)
          else
            Proc.new do |connection|
              isolated(:ModeCallContext).new(connection).instance_eval(&block)
            end
          end
        end

        private def wrap_mode_block_for_plug(plug, block)
          Proc.new do |connection|
            plug.helper_caller(:passive, connection, plug.parent).instance_eval(&block)
          end
        end

        prepend_methods do
          def initialize(*)
            @__ui_modes = Hash[
              self.class.__ui_modes.map { |name, block|
                [name, wrap_mode_block(block)]
              }
            ]

            super
          end
        end

        apply_extension do
          class_state :__ui_modes, default: {}, inheritable: true

          after "load" do
            ([:html] + state(:processor).map(&:extensions).flatten).uniq.each do |extension|
              config.process.watched_paths << File.join(config.presenter.path, "**/*.#{extension}")
            end
          end

          unless ancestors.include?(Plugin)
            isolate ModeCallContext

            on "load" do
              self.class.include_helpers :passive, isolated(:ModeCallContext)
            end

            # Copy ui modes from plugins.
            #
            after "load.plugins" do
              plugs.each do |plug|
                plug.__ui_modes.each do |mode, block|
                  unless @__ui_modes.key?(mode)
                    full_mode = if plug.class.__object_name.name == :default
                      :"#{plug.class.plugin_name}.#{mode}"
                    else
                      :"#{plug.class.plugin_name}(#{plug.class.__object_name.name}).#{mode}"
                    end

                    @__ui_modes[full_mode] = block
                  end
                end
              end
            end
          end
        end

        class_methods do
          def mode(name, &block)
            @__ui_modes[name.to_sym] = block
          end
        end
      end
    end
  end
end
