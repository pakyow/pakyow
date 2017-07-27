module Pakyow
  module Presenter
    # TODO: refactor to LayoutPresenter
    class Template < View
      attr_accessor :name

      class << self
        def load(path)
          html  = File.read(path)
          name  = File.basename(path, ".*").to_sym
          self.new(name, html)
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

        View.new(object: object)
      end
    end
  end
end
