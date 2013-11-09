module Pakyow
  module Presenter
    class Template
      include PartialHelpers
      include DocHelpers

      attr_accessor :name, :doc

      class << self
        def load(path)
          format    = StringUtils.split_at_last_dot(path)[-1]
          contents  = File.read(path)
          name      = File.basename(path, '.*').to_sym

          return self.new(name, contents, format)
        end
      end

      def initialize(name, contents, format = :html)
        @name = name

        if contents.is_a?(Nokogiri::HTML::Document)
          @doc = contents
        else
          processed = Presenter.process(contents, format)
          @doc = Nokogiri::HTML::Document.parse(processed)
        end
      end

      def initialize_copy(original_template)
        super

        # copy doc
        @doc = original_template.doc.dup
      end

      def container(name = :default)
        container = @containers[name.to_sym]
        return view_from_path(container[:path])
      end

      def containers(refind = false)
        @containers = (!@containers || refind) ? find_containers : @containers
      end

      def include_partials(partial_map)
        partials.each_pair do |partial_name, doc|
          doc.replace(partial_map[partial_name].to_s)
          partial_map.delete(partial_name)
        end

        # we have more partials
        if partial_map.count > 0
          # initiate another build if content contains partials
          include_partials(partial_map) if partials(true).count > 0
        end

        return self
      end

      def build(page)
        # add content to each container
        containers.each do |container|
          name = container[0]

          if content = page.content(name)
            container(name).replace(content)
          else
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

      def find_partials
        partials = {}

        @doc.traverse { |e|
          next unless e.is_a?(Nokogiri::XML::Comment)
          next unless match = e.to_html.strip.match(PARTIAL_REGEX)

          name = match[1]
          partials[name.to_sym] = e
        }

        return partials
      end
    end
  end
end
