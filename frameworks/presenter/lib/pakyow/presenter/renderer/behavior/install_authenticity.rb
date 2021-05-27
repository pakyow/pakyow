# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"
require "pakyow/support/safe_string"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module InstallAuthenticity
          extend Support::Extension

          apply_extension do
            build do |view, app:|
              if app.config.presenter.embed_authenticity_token && (head = view.head)
                head.append(Support::SafeStringHelpers.html_safe("<meta name=\"pw-authenticity-token\">"))
                head.append(Support::SafeStringHelpers.html_safe("<meta name=\"pw-authenticity-param\" content=\"#{app.config.security.csrf.param}\">"))
              end
            end

            attach do |presenter|
              presenter.render node: -> {
                node = object.each_significant_node(:meta).find { |meta_node|
                  meta_node.attributes[:name] == "pw-authenticity-token"
                }

                unless node.nil?
                  View.from_object(node)
                end
              } do
                if (signed = @presentables[:__verifier]&.sign(Support::MessageVerifier.key))
                  attributes[:content] = signed
                else
                  remove
                end
              end
            end

            expose do |connection|
              connection.set(:__verifier, connection.verifier)
            end
          end
        end
      end
    end
  end
end
