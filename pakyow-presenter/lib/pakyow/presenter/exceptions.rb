# frozen_string_literal: true

module Pakyow
  module Presenter
    class FrontMatterParsingError < Error; end
    class MissingView < Error; end
    class MissingLayout < MissingView; end
  end
end
