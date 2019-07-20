# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module InstallDevelopmentTools
          extend Support::Extension

          apply_extension do
            attach do |presenter|
              if Pakyow.env?(:development) || Pakyow.env?(:prototype)
                presenter.render node: -> {
                  if body = object.find_first_significant_node(:body)
                    View.from_object(body)
                  end
                } do
                  devtools_html = String.new(
                    <<~HTML
                      <style>
                        .pw-devtools {
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
                          border-top-left-radius: 2px;
                        }

                        .pw-devtools.ui-state-restarting {
                          animation: pulse 1.5s infinite;
                        }

                        @keyframes pulse {
                          0% {
                            opacity: 1;
                          }

                          50% {
                            opacity: 0.5;
                          }

                          100% {
                            opacity: 1;
                          }
                        }

                        .pw-devtools__environment {
                          background: #FF7651;
                          color: #fff;
                          text-transform: uppercase;
                          font-size: 10px;
                          line-height: 12px;
                          font-weight: 600;
                          padding: 5px 5px 4px 5px;
                          border-top-left-radius: 2px;
                          cursor: pointer;
                        }

                        .pw-devtools__versions {
                          padding: 0 5px;
                        }

                        .pw-devtools__mode-selector {
                          -webkit-appearance: none;
                          -moz-appearance: none;
                          -ms-appearance: none;
                          -o-appearance: none;
                          appearance: none;
                          font-size: 11px;
                          font-weight: 500;
                          line-height: 20px;
                          background: none;
                          border: none;
                          color: #fff;
                          outline: none;
                          margin: 0;
                          margin-left: 5px;
                        }
                      }
                      </style>

                      <div class="pw-devtools" data-ui="devtools(environment: #{Pakyow.env}, viewPath: #{@presentables[:__view_path]}); devtools:reloader">
                    HTML
                  )

                  if Pakyow.env?(:prototype)
                    devtools_html << <<~HTML
                      #{InstallDevelopmentTools.ui_modes_html(view, __modes || [:default])}
                    HTML
                  end

                  devtools_html << <<~HTML
                      <div class="pw-devtools__environment" data-ui="devtools:environment">
                        #{Support.inflector.humanize(Pakyow.env)}
                      </div>
                    </div>
                  HTML

                  view.object.append_html(devtools_html)
                end
              end
            end

            expose do |connection|
              if Pakyow.env?(:development) || Pakyow.env?(:prototype)
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
              <div class="pw-devtools__versions">
                UI Mode: <select class="pw-devtools__mode-selector" data-ui="devtools:mode-selector">
                  #{options}
                </select>
              </div>
            HTML
          end
        end
      end
    end
  end
end
