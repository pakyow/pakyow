module Pakyow
  module Presenter
    class FrontMatterParsingError < Error; end
    class MissingView < Error; end
    # TODO: rename to MissingLayout; subclass MissingView?
    class MissingTemplate < Error; end
  end
end
