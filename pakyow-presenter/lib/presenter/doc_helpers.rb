module Pakyow
  module Presenter
    module DocHelpers
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

        return view
      end

      def to_html
        @doc.to_html
      end

      alias :to_s :to_html
    end
  end
end
