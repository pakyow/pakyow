module Pakyow
  module Presenter
    class NokogiriDoc
      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/

      attr_accessor :doc, :scopes

      def breadth_first(doc)
        queue = [doc]
        until queue.empty?
          node = queue.shift
          catch(:reject) {
            yield node
            queue.concat(node.children)
          }
        end
      end

      def path_to(child)
        path = []

        return path if child == @doc

        child.ancestors.each {|a|
          # since ancestors goes all the way to doc root, stop when we get to the level of @doc
          break if a.children.include?(@doc)

          path.unshift(a.children.index(child))
          child = a
        }

        return path
      end

      def path_within_path?(child_path, parent_path)
        parent_path.each_with_index {|pp_step, i|
          return false unless pp_step == child_path[i]
        }

        true
      end

      def doc_from_path(path)
        o = @doc

        # if path is empty we're at self
        return o if path.empty?

        path.each {|i|
          if child = o.children[i]
            o = child
          else
            break
          end
        }

        return o
      end

      def view_from_path(path)
        view = View.from_doc(doc_from_path(path))
        view.related_views << self

        # workaround for nokogiri in jruby (see https://github.com/sparklemotion/nokogiri/issues/1060)
        view.doc.document.errors = []

        return view
      end

      def to_html
        @doc.to_html
      end

      alias :to_s :to_html

      def title=(title)
        return if @doc.nil?

        if o = @doc.css('title').first
          o.inner_html = Nokogiri::HTML::fragment(title.to_s)
        elsif o = @doc.css('head').first
          o.add_child(Nokogiri::HTML::fragment("<title>#{title}</title>"))
        end
      end

      def title
        return unless o = @doc.css('title').first
        o.inner_text
      end

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

        # this solves a memory leak that I believe is being
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
        @doc[name.to_s] = value
      end

      def get_attribute(name)
        @doc[name.to_s]
      end

      def remove_attribute(name)
        @doc.remove_attribute(name.to_s)
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

      def append(appendable)
        content = appendable.is_a?(NokogiriDoc) ? appendable.doc : appendable
        @doc.add_child(content)
      end

      def prepend(prependable)
        content = prependable.is_a?(NokogiriDoc) ? prependable.doc : prependable
        if first_child = @doc.children.first
          first_child.add_previous_sibling(content)
        else
          @doc = content
        end
      end

      def after(insertable)
        content = insertable.is_a?(NokogiriDoc) ? insertable.doc : insertable
        @doc.after(content)
      end

      def before(insertable)
        content = insertable.is_a?(NokogiriDoc) ? insertable.doc : insertable
        @doc.before(content)
      end

      def replace(replacement)
        content = replacement.is_a?(NokogiriDoc) ? replacement.doc : replacement

        if @doc.parent.nil?
          @doc.children.remove
          @doc.inner_html = content
        else
          @doc.replace(content)
        end
      end

      def scope(name)
        scopes.select { |b| b[:scope] == name }
      end

      def prop(scope_name, prop_name)
        return [] unless scope = scopes.select { |b| b[:scope] == scope_name }[0]
        scope[:props].select { |b| b[:prop] == prop_name }
      end

      def container(name)
        container = @containers[name.to_sym]
        return container[:doc]
      end

      def scopes(refind = false)
        @scopes = (!@scopes || refind) ? find_scopes : @scopes
      end

      def containers(refind = false)
        @containers = (!@containers || refind) ? find_containers : @containers
      end

      def partials(refind = false)
        @partials = (!@partials || refind) ? find_partials : @partials
      end

      def ==(o)
        to_html == o.to_html
      end

      def tagname
        @doc.name
      end

      def option(value: nil)
        @doc.css('option[value="' + value.to_s + '"]').first
      end

      private

      # returns an array of hashes that describe each scope
      def find_scopes(doc = @doc, ignore_root = false)
        scopes = []
        breadth_first(doc) {|o|
          next if o == doc && ignore_root
          next if !scope = o[Config::Presenter.scope_attribute]

          scopes << {
            :doc => NokogiriDoc.from_doc(o),
            :scope => scope.to_sym,
            :props => find_props(o)
          }

          if o == doc
            # this is the root node, which we need as the first hash in the
            # list of scopes, but we don't want to nest other scopes inside
            # of it in this case
            scopes.last[:nested] = []
          else
            scopes.last[:nested] = find_scopes(o, true)
            # reject so children aren't traversed
            throw :reject
          end
        }

        return scopes
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
          props << { :prop => prop.to_sym, :doc => NokogiriDoc.from_doc(so) }
        }

        return props
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
