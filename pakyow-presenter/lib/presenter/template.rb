module Pakyow
  module Presenter
    class Template < View
      attr_accessor :name, :doc

      class << self
        def load(path)
          format    = Utils::String.split_at_last_dot(path)[-1]
          contents  = File.read(path)
          name      = File.basename(path, '.*').to_sym

          return self.new(name, contents, format)
        end
      end

      def initialize(name, contents = '', format = :html)
        @name = name
        super(contents, format)
      end

      def initialize_copy(original_template)
        super

        # copy doc
        @doc = original_template.doc.dup
        @context = original_template.context
      end

      def container(name = :default)
        View.from_doc(@doc.container(name.to_sym))
      end

      def build(page)
        # add content to each container
        #TODO this is going to have to change some; need access to container's nokogiridoc
        @doc.containers.each do |container|
          name = container[0]

          begin
            container[1][:doc].replace(page.content(name))
          rescue MissingContainer
            Pakyow.logger.debug "No content for '#{name}' in page '#{page.path}'"
          end
        end

        return View.from_doc(doc)
      end
    end
  end
end
