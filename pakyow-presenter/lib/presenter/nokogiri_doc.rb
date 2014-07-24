module Pakyow
  module Presenter
    class NokogiriDoc
      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/

      include DocHelpers
      include TitleHelpers

      attr_accessor :doc, :bindings

      def self.from_doc(doc)
        instance = allocate
        instance.doc = doc
        return instance
      end

      def initialize(html)
        if html.match(/<html.*>/)
          @doc = Nokogiri::HTML::Document.parse(html)
        else
          @doc = Nokogiri::HTML.fragment(html)
        end
      end

      def initialize_copy(original_doc)
        super

        #TODO this solves a memory leak that I believe is being
        # caused by Nokogiri; don't like this approach much
        # since it negatively affects performance
        #
        # https://gist.github.com/bryanp/2048ae4a38f94c9d97ef
        if original_doc.is_a?(Nokogiri::HTML::DocumentFragment)
          @doc = Nokogiri::HTML.fragment(original_doc.doc.to_html)
        else
          @doc = original_doc.doc.dup
        end
      end

      def set_attribute(name, value)
        @doc[name] = value
      end

      def get_attribute(name)
        @doc[name]
      end

      def remove_attribute(name)
        @doc.remove_attribute(name)
      end

      def update_attribute(name, value)
        if !@doc.is_a?(Nokogiri::XML::Element) && @doc.children.count == 1
          @doc.children.first[name] = value
        else
          @doc.set_attribute(name, value)
        end
      end

      def remove
        if @doc.parent.nil?
          # best we can do is to remove the children
          @doc.children.remove
        else
          @doc.remove
        end
      end

      def clear
        return if @doc.blank?
        @doc.inner_html = ''
      end

      def text
        @doc.inner_text
      end

      def text=(text)
        @doc.content = text.to_s
      end

      def html
        @doc.inner_html
      end

      def html=(html)
        @doc.inner_html = Nokogiri::HTML.fragment(html.to_s)
      end

      def append(appendable_doc)
        @doc.add_child(appendable_doc.doc)
      end

      def prepend(prependable_doc)
        if first_child = @doc.children.first
          first_child.add_previous_sibling(prependable_doc.doc)
        else
          @doc = prependable_doc.doc
        end
      end

      def after(insertable_doc)
        @doc.after(insertable_doc.doc)
      end

      def before(insertable_doc)
        @doc.before(insertable_doc.doc)
      end

      def replace(replacement_doc)
        if @doc.parent.nil?
          @doc.children.remove
          @doc.inner_html = replacement_doc
        else
          @doc.replace(replacement_doc)
        end
      end

      def scope(name)
        bindings.select { |b| b[:scope] == name }.map { |scope_doc|
          NokogiriDoc.from_doc(scope_doc[:doc])
        }
      end

      def prop(scope_name, prop_name)
        return [] unless binding = bindings.select { |b| b[:scope] == scope_name }[0]
        binding[:props].select { |b| b[:prop] == prop_name }.map { |prop_doc|
          NokogiriDoc.from_doc(prop_doc[:doc])
        }
      end

      def container(name)
        container = @containers[name.to_sym]
        return NokogiriDoc.from_doc(container[:doc])
      end

      def bindings(refind = false)
        @bindings = (!@bindings || refind) ? find_bindings : @bindings
      end

      def containers(refind = false)
        @containers = (!@containers || refind) ? find_containers : @containers
      end

      def partials(refind = false)
        @partials = (!@partials || refind) ? find_partials : @partials
      end

      private

      # returns an array of hashes that describe each scope
      def find_bindings(doc = @doc, ignore_root = false)
        bindings = []
        breadth_first(doc) {|o|
          next if o == doc && ignore_root
          next if !scope = o[Config::Presenter.scope_attribute]

          bindings << {
            :doc => o,
            :scope => scope.to_sym,
            :props => find_props(o)
          }

          if o == doc
            # this is the root node, which we need as the first hash in the
            # list of bindings, but we don't want to nest other scopes inside
            # of it in this case
            bindings.last[:nested_bindings] = []
          else
            bindings.last[:nested_bindings] = find_bindings(o, true)
            # reject so children aren't traversed
            throw :reject
          end
        }

        # find unscoped props
        unless doc[Config::Presenter.scope_attribute]
          bindings.unshift({
            :scope => nil,
            :props => find_props(doc),
            :nested_bindings => []
          })
        end

        return bindings
      end

      # returns an array of hashes, each with the container name and doc
      def find_containers
        containers = {}

        @doc.traverse {|e|
          next unless e.is_a?(Nokogiri::XML::Comment)
          next unless match = e.text.strip.match(/@container( ([a-zA-Z0-9\-_]*))*/)
          name = match[2] || :default

          containers[name.to_sym] = { doc: NokogiriDoc.from_doc(e) }
        }

        return containers
      end

      def find_props(o)
        props = []
        breadth_first(o) {|so|
          # don't go into deeper scopes
          throw :reject if so != o && so[Config::Presenter.scope_attribute]

          next unless prop = so[Config::Presenter.prop_attribute]
          props << { :prop => prop.to_sym, :doc => so }
        }

        return props
      end

      def find_partials
        partials = []

        @doc.traverse { |e|
          next unless e.is_a?(Nokogiri::XML::Comment)
          next unless match = e.to_html.strip.match(PARTIAL_REGEX)

          name = match[1]
          partials << [name.to_sym, e]
        }

        return partials
      end

    end
  end
end

