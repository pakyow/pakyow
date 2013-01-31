require 'support/helper'

class FnContextTest < MiniTest::Unit::TestCase
  def test_helpers_are_included
    assert FnContext.ancestors.include?(Pakyow::Helpers), "Helpers aren't available for FnContext"
  end
end
