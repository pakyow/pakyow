module Pakyow
  module Presenter
    class Template < View
      include DocHelpers
      include TitleHelpers

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
        @composer = original_template.composer
      end

      def container(name = :default)
        container = @containers[name.to_sym]
        return view_from_path(container[:path])
      end

      def containers(refind = false)
        @containers = (!@containers || refind) ? find_containers : @containers
      end

      def build(page)
        # add content to each container
        containers.each do |container|
          name = container[0]

          begin
            container(name).replace(page.content(name))
          rescue MissingContainer
            Pakyow.logger.debug "No content for '#{name}' in page '#{page.path}'"
          end
        end

        return View.from_doc(doc)
      end

      private

      # returns an array of hashes, each with the container name and doc
      def find_containers
        containers = {}

        @doc.traverse {|e|
          next unless e.is_a?(Nokogiri::XML::Comment)
          next unless match = e.text.strip.match(/@container( ([a-zA-Z0-9\-_]*))*/)
          name = match[2] || :default

          containers[name.to_sym] = { doc: e, path: path_to(e) }
        }

        return containers
      end
    end
  end
end
