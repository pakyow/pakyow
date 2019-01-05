# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InsertPrototypeBar
        def call(renderer)
          if renderer.rendering_prototype?
            if body_node = renderer.presenter.view.object.find_significant_nodes(:body)[0]
              body_node.append <<~HTML
                <div class="pw-prototype" style="position: fixed; left: 0; right: 0; bottom: 0; width: 100%; height: 20px; background: #111; color: #bbb; text-align: right; font-size: 11px; line-height: 20px">
                  <div style="background: #777; color: #111; text-transform: uppercase; font-size: 10px; line-height: 20px; padding: 0 10px; float: right">
                    Prototype
                  </div>

                  #{ui_modes_html(renderer)}
                </div>
              HTML
            end
          end
        end

        private

        def ui_modes_html(renderer)
          modes = renderer.presenter.view.object.find_significant_nodes(:mode).map { |node|
            node.label(:mode)
          }

          modes.unshift(
            (renderer.presenter.view.info(:mode) || :default).to_sym
          ).uniq!

          options = modes.map { |mode|
            selected = if mode == renderer.mode.to_sym
              " selected=\"selected\""
            else
              ""
            end

            nice_mode = Support.inflector.humanize(Support.inflector.underscore(mode))
            "<option value=\"#{mode}\"#{selected}>#{nice_mode}</option>"
          }.join

          <<~HTML
            UI Mode: <select onchange="document.location = window.location.pathname + '?mode=' + this.value " style="-webkit-appearance: none; -moz-appearance: none; -ms-appearance: none; -o-appearance: none; appearance: none; font-size: 11px; line-height: 20px; background: none; border: none; color: #bbb; outline: none; margin-right: 10px">
              #{options}
            </select>
          HTML
        end
      end
    end
  end
end
