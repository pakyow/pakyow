# frozen_string_literal: true

require_relative "../view"

module Pakyow
  module Presenter
    module Views
      class Layout < View
        attr_accessor :name

        class << self
          def load(path, content: nil, **args)
            new(File.basename(path, ".*").to_sym, content || File.read(path), **args)
          end
        end

        def initialize(name, html = "", **args)
          @name = name
          super(html, **args)
        end

        def container(name = Views::Page::DEFAULT_CONTAINER)
          @object.container(name.to_sym)
        end

        def build(page)
          @object.each_significant_node(:container) do |container_node|
            container_node.replace(page.content(container_node.label(:container)))
          end

          View.from_object(@object).add_info(info, page.info)
        end
      end
    end
  end
end
