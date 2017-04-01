module Pakyow
  module Presenter
    class Template < View
      attr_accessor :name, :doc

      class << self
        def load(path)
          html  = File.read(path)
          name  = File.basename(path, '.*').to_sym

          self.new(name, html)
        end
      end

      def initialize(name, html = '')
        @name = name
        super(html)
      end

      def initialize_copy(original_template)
        super

        # copy doc
        @doc = original_template.doc.dup
      end

      def container(name = :default)
        View.from_doc(@doc.container(name.to_sym))
      end

      def build(page)
        @doc.containers.each do |container|
          name = container[0]

          begin
            container[1][:doc].replace(page.content(name))
          rescue MissingContainer
            # This hasn't proven to be useful in dev (or prd for that matter)
            # so decided to remove it. It'll save us from filling console / log
            # with information that will most likely just be ignored.
            #
            # Pakyow.logger.info "No content for '#{name}' in page '#{page.path}'"
          end
        end

        View.from_doc(doc)
      end
    end
  end
end
