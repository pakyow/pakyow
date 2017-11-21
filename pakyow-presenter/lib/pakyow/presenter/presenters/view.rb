# frozen_string_literal: true

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    class ViewPresenter < Presenter
      extend Support::ClassMaker

      class << self
        attr_reader :path, :block

        def make(path, state: nil, &block)
          path = String.normalize_path(path)
          super(name_from_path(path), state: state, path: path, block: block) {}
        end

        def name_from_path(path)
          return :root if path == "/"
          # TODO: fill in the rest of this
          # / => Root
          # /posts => Posts
          # /posts/show => PostsShow
        end
      end

      attr_reader :template, :page, :partials

      def initialize(template: nil, page: nil, partials: [], **args)
        @template, @page, @partials = template, page, partials
        @view = template.build(page).mixin(partials)
        super(@view, **args)
      end

      def to_html
        if block = self.class.block
          instance_exec(&block)
        end

        if title = page.info(:title)
          view.title = title
        end

        super
      end

      alias :to_str :to_html
    end
  end
end
