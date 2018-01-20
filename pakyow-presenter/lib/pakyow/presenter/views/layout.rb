# frozen_string_literal: true

module Pakyow
  module Presenter
    class Layout < View
      attr_accessor :name

      class << self
        def load(path, content: nil, **args)
          self.new(File.basename(path, ".*").to_sym, content || File.read(path), **args)
        end
      end

      def initialize(name, html = "", **args)
        @name = name
        super(html, **args)
      end

      def container(name = Page::DEFAULT_CONTAINER)
        @object.container(name.to_sym)
      end

      def build(page)
        @object.find_significant_nodes(:container).each do |container_node|
          container_node.replace(page.content(container_node.name))
        end

        View.from_object(@object).add_info(info, page.info)
      end
    end
  end
end
