# frozen_string_literal: true

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    class ViewPresenter < Presenter
      extend Support::Makeable

      class << self
        attr_reader :path, :block

        def make(path, namespace: nil, **kwargs, &block)
          path = String.normalize_path(path)
          super(name_from_path(path, namespace), path: path, block: block, **kwargs) {}
        end

        def name_from_path(path, namespace)
          return unless path && namespace

          path_parts = path.split("/").reject(&:empty?).map(&:to_sym)

          # last one is the actual name, everything else is a namespace
          classname = path_parts.pop

          Support::ClassName.new(
            Support::ClassNamespace.new(
              *(namespace.parts + path_parts)
            ), classname
          )
        end
      end

      attr_reader :template, :page, :partials

      def initialize(template: nil, page: nil, partials: [], **args)
        @template, @page, @partials = template, page, partials

        @template.mixin(partials)
        @page.mixin(partials)

        @view = template.build(page)
        super(@view, **args)
      end

      def to_html(clean: true)
        if block = self.class.block
          instance_exec(&block)
        end

        super
      end
    end
  end
end
