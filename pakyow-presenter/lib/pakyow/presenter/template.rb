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

      def initialize_copy(original_template)
        super

        # copy doc
        @doc = original_template.doc.dup
      end

      def container(name = :default)
        doc.container(name.to_sym)
      end

      def build(page)
        doc.containers.each do |container|
          container.replace(page.content(container.name))
        end

        View.from_doc(doc)
      end
    end
  end
end
