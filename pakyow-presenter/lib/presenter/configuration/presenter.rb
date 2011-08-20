module Pakyow
  module Configuration
    class Presenter
      class << self
        attr_accessor :view_caching, :javascripts, :stylesheets, :view_dir, :default_view
        
        # Location of javascripts
        def javascripts
          @javascripts || '/javascripts'
        end
        
        # Location of stylesheets
        def stylesheets
          @stylesheets || '/stylesheets'
        end

        def view_dir
          @view_dir || "#{Configuration::Base.app.root}/app/views"
        end
        
        def view_caching
          @view_caching || false
        end

        def default_view
          @default_view || "pakyow.html"
        end

      end
    end
  end
end
