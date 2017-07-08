module Pakyow
  module Presenter
    # TODO: refactor to LayoutPresenter
    class Template < View
      attr_accessor :name, :doc

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
        doc.container(name.to_sym)
      end

      def build(page)
        doc.containers.each do |container|
          container.replace(page.content(container.name))
        end

        View.new(doc: doc)
      end
    end
  end
end
