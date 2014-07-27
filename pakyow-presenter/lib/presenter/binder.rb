module Pakyow
  module Presenter
    # A singleton that manages route sets.
    #
    class Binder
      include Singleton
      include Helpers

      attr_reader :sets

      def initialize
        @sets = {}
      end

      #TODO want to do this for all sets?
      def reset
        @sets = {}
        self
      end

      # Creates a new set.
      #
      def set(name, &block)
        @sets[name] = BinderSet.new
        @sets[name].instance_exec(&block)
      end

      def bind(datum, view, bindings, ctx)
        scope_info = view.doc.bindings.first
        bind_data_to_scope(datum, scope_info, bindings, ctx)
      end

      def bind_data_to_scope(data, scope_info, bindings, ctx)
        return unless data
        return unless scope_info

        scope = scope_info[:scope]
        bind_data_to_root(data, scope, bindings)

        scope_info[:props].each { |prop_info|
          catch(:unbound) {
            prop = prop_info[:prop]

            if data_has_prop?(data, prop) || has_prop?(prop, scope, bindings)
              value = value_for_prop(prop, scope, data, bindings, ctx)
              doc = prop_info[:doc]

              if View.form_field?(doc.name)
                bind_to_form_field(doc, scope, prop, value, data)
              end

              bind_data_to_doc(doc, value)
            else
              handle_unbound_data(scope, prop)
            end
          }
        }
      end

      def bind_data_to_root(data, scope, bindings)
        return unless value = value_for_prop(:_root, scope, data, bindings)
        value.is_a?(Hash) ? self.bind_attributes_to_doc(value, self.doc) : self.bind_value_to_doc(value, self.doc)
      end

      def bind_data_to_doc(doc, data)
        data.is_a?(Hash) ? self.bind_attributes_to_doc(data, doc) : self.bind_value_to_doc(data, doc)
      end

      def data_has_prop?(data, prop)
        (data.is_a?(Hash) && (data.key?(prop) || data.key?(prop.to_s))) || (!data.is_a?(Hash) && data.class.method_defined?(prop))
      end

			#TODO port to NokogiriDoc
      def bind_value_to_doc(value, doc)
        value = String(value)

        tag = doc.name
        return if View.tag_without_value?(tag)

        if View.self_closing_tag?(tag)
          # don't override value if set
          if !doc['value'] || doc['value'].empty?
            doc['value'] = value
          end
        else
          doc.inner_html = value
        end
      end

			#TODO port to NokogiriDoc
      def bind_attributes_to_doc(attrs, doc)
        attrs.each do |attr, v|
          case attr
          when :content
            v = v.call(doc.inner_html) if v.is_a?(Proc)
            bind_value_to_doc(v, doc)
            next
          when :view
            v.call(self)
            next
          end

          attr = attr.to_s
          attrs = Attributes.new(doc)
          v = v.call(attrs.send(attr)) if v.is_a?(Proc)

          if v.nil?
            doc.remove_attribute(attr)
          else
            attrs.send(:"#{attr}=", v)
          end
        end
      end

			#TODO port to NokogiriDoc
      def bind_to_form_field(doc, scope, prop, value, bindable)
        set_form_field_name(doc, scope, prop)

        # special binding for checkboxes and radio buttons
        if doc.name == 'input' && (doc[:type] == 'checkbox' || doc[:type] == 'radio')
          bind_to_checked_field(doc, value)
        # special binding for selects
        elsif doc.name == 'select'
          bind_to_select_field(doc, scope, prop, value, bindable)
        end
      end

			#TODO port to NokogiriDoc
      def bind_to_checked_field(doc, value)
        if value == true || (doc[:value] && doc[:value] == value.to_s)
          doc[:checked] = 'checked'
        else
          doc.delete('checked')
        end

        # coerce to string since booleans are often used and fail when binding to a view
        value = value.to_s
      end

      def bind_to_select_field(doc, scope, prop, value, bindable)
        create_select_options(doc, scope, prop, value, bindable)
        select_option_with_value(doc, value)
      end

			#TODO port to NokogiriDoc
      def set_form_field_name(doc, scope, prop)
        return if doc['name'] && !doc['name'].empty? # don't overwrite the name if already defined
        doc['name'] = "#{scope}[#{prop}]"
      end

			#TODO port to NokogiriDoc
      def create_select_options(doc, scope, prop, value, bindable)
        return unless options = Pakyow.app.presenter.binder.options_for_prop(prop, scope, bindable, ctx)

        option_nodes = Nokogiri::HTML::DocumentFragment.parse ""
        Nokogiri::HTML::Builder.with(option_nodes) do |h|
          until options.length == 0
            catch :optgroup do
              o = options.first

              # an array containing value/content
              if o.is_a?(Array)
                h.option o[1], :value => o[0]
                options.shift
                # likely an object (e.g. string); start a group
              else
                h.optgroup(:label => o) {
                  options.shift

                  options[0..-1].each_with_index { |o2,i2|
                    # starting a new group
                    throw :optgroup if !o2.is_a?(Array)

                    h.option o2[1], :value => o2[0]
                    options.shift
                  }
                }
              end
            end
          end
        end

        # remove existing options
        doc.children.remove

        # add generated options
        doc.add_child(option_nodes)
      end

			#TODO port to NokogiriDoc
      def select_option_with_value(doc, value)
        return unless o = doc.css('option[value="' + value.to_s + '"]').first
        o[:selected] = 'selected'
      end

      def handle_unbound_data(scope, prop)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]")
        throw :unbound
      end

      def value_for_prop(prop, scope, bindable, bindings = {}, context)
        @context = context
        binding = nil
        @sets.each {|set|
          binding = set[1].match_for_prop(prop, scope, bindable, bindings)
          break if binding
        }

        if binding
          binding_eval = BindingEval.new(prop, bindable, context)

          case binding.arity
          when 0
            binding_eval.instance_exec(&binding)
          when 1
            self.instance_exec(bindable, &binding)
          when 2
            self.instance_exec(bindable, binding_eval.value, &binding)
          end
        else
          # default
          prop_value_for_bindable(bindable, prop)
        end
      end

      def prop_value_for_bindable(bindable, prop)
        return bindable[prop] if bindable.is_a?(Hash)
        return bindable.send(prop) if bindable.class.method_defined?(prop)
      end

      def options_for_prop(*args)
        match = nil
        @sets.each {|set|
          match = set[1].options_for_prop(*args)
          break if match
        }

        return match
      end

      def has_prop?(*args)
        has = nil
        @sets.each {|set|
          has = set[1].has_prop?(*args)
          break if has
        }

        return has
      end
    end
  end
end
