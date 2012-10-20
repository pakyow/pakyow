module Pakyow
  module Configuration
    class Presenter
      class << self
        attr_accessor :view_caching, :javascripts, :stylesheets, :view_dir, :default_view,
        :scope_attribute, :prop_attribute, :container_attribute
        
        # Location of javascripts
        def javascripts
          @javascripts || '/javascripts'
        end
        
        # Location of stylesheets
        def stylesheets
          @stylesheets || '/stylesheets'
        end

        def view_dir
          @view_dir || "#{Configuration::Base.app.root}/views"
        end
        
        def view_caching
          @view_caching || false
        end

        def default_view
          @default_view || "pakyow.html"
        end

        def scope_attribute
          @scope_attribute || "data-scope"
        end

        def prop_attribute
          @prop_attribute || "data-prop"
        end

        def container_attribute
          @container_attribute || "data-container"
        end

      end
    end
  end
end
