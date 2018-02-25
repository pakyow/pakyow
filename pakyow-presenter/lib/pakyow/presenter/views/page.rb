# frozen_string_literal: true

require "yaml"

module Pakyow
  module Presenter
    class Page < View
      DEFAULT_CONTAINER = :main

      attr_reader :name, :path

      class << self
        def load(path, content: nil, **args)
          self.new(File.basename(path, ".*").to_sym, content || File.read(path), **args, path: path)
        end
      end

      def initialize(name, html = "", path: nil, info: {}, **args)
        @containers = {}
        parse_content(html)
        @name, @path = name, path
        info["layout"] ||= :default
        super(html, info: info, **args)
      end

      def initialize_copy(_)
        super

        @containers = Hash[@containers.map { |key, value|
          [key, value.dup]
        }]
      end

      def content(container)
        container = container.to_sym

        if container == DEFAULT_CONTAINER
          @object
        elsif @containers.key?(container)
          @containers[container].object
        else
          nil
        end
      end

      def mixin(partials)
        super

        @containers.values.each do |view|
          view.mixin(partials)
        end
      end

      def container_views
        [View.from_object(@object)].concat(@containers.values)
      end

      protected

      WITHIN_REGEX = /<!--\s*@within\s*([a-zA-Z0-9\-_]*)\s*-->(.*?)<!--\s*\/within\s*-->/m

      def parse_content(html)
        html.scan(WITHIN_REGEX) do |match|
          container_name = match[0].to_sym
          @containers[container_name] = View.from_object(StringDoc.new(match[1]))
        end

        html.gsub!(WITHIN_REGEX, "")
      end
    end
  end
end
