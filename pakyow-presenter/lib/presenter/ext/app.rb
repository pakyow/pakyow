module Pakyow
  class App
    class << self
      def bindings(set_name = :main, &block)
        if set_name && block
          bindings[set_name] = block
        else
          @bindings ||= {}
        end
      end

      def processor(*args, &block)
        args.each {|format|
          processors[format] = block
        }
      end

      def processors
        @processors ||= {}
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end

    def content_for_code(code)
      content = File.open(
        File.join(
          File.expand_path(
            '../../../../../', __FILE__),
            'pakyow-core',
            'lib',
            'views',
            'errors',
            code.to_s + '.html'
          )
      ).read + File.open(
        File.join(
          File.expand_path(
            '../../../', __FILE__),
            'views',
            'errors',
            code.to_s + '.html'
          )
      ).read

      path = String.normalize_path(request.path)
      path = '/' if path.empty?

      content.gsub!('{view_path}', path == '/' ? 'index.html' : "#{path}.html")

      template = presenter.store.template(:default)
      template.container(:default).replace(content)
      template.to_html
    end
  end
end
