module Pakyow
  class App
    class << self
      RESOURCE_ACTIONS[:presenter] = Proc.new { |app, set_name, _, _|
        app.bindings { scope(set_name) { restful(set_name) } }
      }

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

    protected

    def presenter_handle_error(code)
      return if !config.app.errors_in_browser || req.format != :html
      response.body = [content_for_code(code)]
    end

    def content_for_code(code)
      content = ERB.new(File.read(path_for_code(code))).result(binding)
      page = Presenter::Page.new(:presenter, content, '/')
      composer = presenter.compose_at('/', page: page)
      composer.to_html
    end

    def path_for_code(code)
      File.join(
        File.expand_path('../../../', __FILE__),
        'views',
        'errors',
        code.to_s + '.erb'
      )
    end
  end
end
