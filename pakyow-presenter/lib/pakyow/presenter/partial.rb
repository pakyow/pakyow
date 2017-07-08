module Pakyow
  module Presenter
    # TODO: refactor to PartialPresenter
    class Partial < View
      attr_accessor :name

      class << self
        def load(path)
          html  = File.read(path)
          name  = File.basename(path, ".*")[1..-1].to_sym
          self.new(name, html)
        end
      end

      def initialize(name, html = "")
        @name = name
        super(html)
      end
    end
  end
end
