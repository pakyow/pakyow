# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InsertPrototypeBar
        def call(presenter)
          if Pakyow.env?(:prototype) && presenter.respond_to?(:__mode)
            if body_node = presenter.view.object.find_first_significant_node(:body)
              body_node.append_html <<~HTML
                <style>
                  .pw-prototype {
                    font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif;
                    display:flex;
                    align-items: center;
                    position: fixed;
                    z-index: 1000;
                    right: 0;
                    bottom: 0;
                    background: #156eed;
                    color: #fff;
                    font-size: 11px;
                    line-height: 11px;
                    font-weight: 500;
                    border-top-left-radius: 1px;
                    padding-left: 5px;
                  }

                  .pw-prototype-tag {
                    background: #ff8b6c;
                    color: #fff;
                    text-transform: uppercase;
                    font-size: 10px;
                    line-height: 12px;
                    font-weight: 600;
                    padding: 5px 5px 4px 5px;
                    margin-left: 10px;
                  }
                </style>

                <div class="pw-prototype">
                  #{ui_modes_html(presenter)}

                  <div class="pw-prototype-tag">
                    Prototype
                  </div>
                </div>
              HTML
            end
          end
        end

        private

        def ui_modes_html(presenter)
          modes = presenter.view.object.each_significant_node(:mode).map { |node|
            node.label(:mode)
          }

          modes.unshift(
            (presenter.view.info(:mode) || :default).to_sym
          ).uniq!

          options = modes.map { |mode|
            selected = if mode == presenter.__mode.to_sym
              " selected=\"selected\""
            else
              ""
            end

            nice_mode = Support.inflector.humanize(Support.inflector.underscore(mode))
            "<option value=\"#{mode}\"#{selected}>#{nice_mode}</option>"
          }.join

          <<~HTML
            UI Mode: <select onchange="document.location = window.location.pathname + '?mode=' + this.value " style="-webkit-appearance: none; -moz-appearance: none; -ms-appearance: none; -o-appearance: none; appearance: none; font-size: 11px; font-weight: 500; line-height: 20px; background: none; border: none; color: #fff; outline: none; margin: 0; margin-left: 5px;">
              #{options}
            </select>
          HTML
        end
      end
    end
  end
end
