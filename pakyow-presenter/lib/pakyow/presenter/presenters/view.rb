# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    class ViewPresenter < Presenter
      extend Support::Makeable

      class << self
        using Support::Refinements::String::Normalization

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

      attr_reader :layout, :page, :partials

      def initialize(layout: nil, page: nil, partials: [], **args)
        @layout, @page, @partials = layout, page, partials

        @layout.mixin(partials)
        @page.mixin(partials)

        @view = layout.build(page)
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
