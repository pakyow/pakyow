module Pakyow
  module Presenter
    class Binder
      include Pakyow::GeneralHelpers

      class << self
        attr_accessor :options
        
        def binder_for(klass)
          View.binders = {} unless View.binders
          View.binders[klass.to_s.to_sym] = self
        end
        
        def options_for(*args)
          self.options = {} unless self.options
          self.options[args[0]] = args[1]
        end
      end
      
      attr_accessor :bindable, :object
      
      def initialize(bindable, object)
        self.bindable = bindable
        self.object = object
      end
      
      def fetch_options_for(attribute)
        if self.class.options
          if options = self.class.options[attribute]
            unless options.is_a?(Array) || options.is_a?(Hash)
              options = self.send(options)
            end
          
            return options
          end
        end
      end
      
      def action
        unless routes = Pakyow.app.restful_routes[bindable.class.name.to_sym]
          Log.warn "Attempting to bind object to #{bindable.class.name.downcase}[action] but could not find restful routes for #{bindable.class.name}."
          return {}
        end
        
        if id = bindable.id
          self.object.add_child('<input type="hidden" name="_method" value="put">')
          

          action = routes[:update].gsub(':id', id.to_s)
          method = "post"
        else
          action = routes[:create]
          method = "post"
        end
        
        return { :action => action, :method => method }
      end
    end
  end
end
