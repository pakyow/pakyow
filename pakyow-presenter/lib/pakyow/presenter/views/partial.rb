# frozen_string_literal: true

module Pakyow
  module Presenter
    class Partial < View
      attr_accessor :name

      class << self
        def load(path, content: nil, **args)
          name = File.basename(path, ".*")
          name = name[1..-1] if name.start_with?("_")
          self.new(name.to_sym, content || File.read(path), **args)
        end
      end

      def initialize(name, html = "", **args)
        @name = name
        super(html, **args)
      end
    end
  end
end
