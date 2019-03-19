# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallAuthenticity
        def call(renderer)
          renderer.presenter.view.object.each_significant_node(:meta) do |node|
            case node.attributes[:name]
            when "pw-authenticity-token"
              node.attributes[:content] = renderer.connection.verifier.sign(renderer.authenticity_client_id)
            end
          end
        end
      end
    end
  end
end
