module Pakyow
  module Presenter
    # TODO: refactor to PartialPresenter
    class Partial < View
      attr_accessor :name

      class << self
        def load(path, content: nil)
          self.new(File.basename(path, ".*")[1..-1].to_sym, content || File.read(path))
        end
      end

      def initialize(name, html = "")
        @name = name
        super(html)
      end
    end
  end
end
