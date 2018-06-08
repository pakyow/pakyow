# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    class ViewPresenter < Presenter
      extend Support::Makeable

      class << self
        using Support::Refinements::String::Normalization

        attr_reader :path

        def make(path, namespace: nil, **kwargs, &block)
          path = String.normalize_path(path)
          super(name_from_path(path, namespace), path: path, **kwargs, &block)
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

        def perform(&block)
          @block = block
        end

        def block
          if instance_variable_defined?(:@block)
            @block
          else
            Proc.new do
              presentables.each do |name, value|
                name_parts = name.to_s.split(":")

                channel = if name_parts.count > 1
                  name_parts[1..-1]
                else
                  nil
                end

                [name_parts[0], Support.inflector.singularize(name_parts[0])].each do |name_varient|
                  found = find(name_varient, channel: channel)

                  unless found.nil?
                    found.present(value); break
                  end
                end
              end
            end
          end
        end
      end

      attr_reader :layout, :page, :partials

      # @api private
      attr_accessor :presentables

      def initialize(layout: nil, page: nil, partials: [], **args)
        @layout, @page, @partials = layout, page, partials

        @layout.mixin(partials)
        @page.mixin(partials)

        @view = layout.build(page)
        super(@view, **args)
      end

      def to_html(clean_bindings: true, clean_versions: true)
        perform
        super
      end

      def perform
        instance_exec(&self.class.block)
      end
    end
  end
end
