# frozen_string_literal: true

module Pakyow
  module Presenter
    class Layout < View
      attr_accessor :name

      class << self
        def load(path, content: nil)
          self.new(File.basename(path, ".*").to_sym, content || File.read(path))
        end
      end

      def initialize(name, html = "")
        @name = name
        super(html)
      end

      def container(name = :default)
        object.container(name.to_sym)
      end

      def build(page)
        object.find_significant_nodes(:container).each do |container_node|
          container_node.replace(page.content(container_node.name))
        end

        View.new(object: object).add_info(self.info, page.info)
      end
    end
  end
end
