# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module InsertPrototypeBar
        extend Support::Extension

        apply_extension do
          attach do |presenter|
            if Pakyow.env?(:prototype)
              presenter.render node: -> {
                if body = object.find_first_significant_node(:body)
                  View.from_object(body)
                end
              } do
                view.object.append_html <<~HTML
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
                    #{InsertPrototypeBar.ui_modes_html(view, __modes || [:default])}

                    <div class="pw-prototype-tag">
                      Prototype
                    </div>
                  </div>
                HTML
              end
            end
          end

          expose do |connection|
            if Pakyow.env?(:prototype)
              connection.set(:__modes, connection.params[:modes])
            end
          end
        end

        # @api private
        def self.ui_modes_html(view, current_modes)
          current_modes = current_modes.map(&:to_sym)

          modes = view.object.each_significant_node(:mode).map { |node|
            node.label(:mode)
          }

          modes.unshift(
            (view.info(:mode) || :default).to_sym
          ).uniq!

          options = modes.map { |each_mode|
            selected = if current_modes.include?(each_mode)
              " selected=\"selected\""
            else
              ""
            end

            nice_mode = Support.inflector.humanize(Support.inflector.underscore(each_mode))
            "<option value=\"#{each_mode}\"#{selected}>#{nice_mode}</option>"
          }.join

          <<~HTML
            UI Mode: <select onchange="document.location = window.location.pathname + '?modes[]=' + this.value " style="-webkit-appearance: none; -moz-appearance: none; -ms-appearance: none; -o-appearance: none; appearance: none; font-size: 11px; font-weight: 500; line-height: 20px; background: none; border: none; color: #fff; outline: none; margin: 0; margin-left: 5px;">
              #{options}
            </select>
          HTML
        end
      end
    end
  end
end
