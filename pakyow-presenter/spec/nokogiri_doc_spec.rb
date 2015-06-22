require_relative 'support/helper'

describe Pakyow::Presenter::NokogiriDoc do
  let(:doc) { doctype.new(html) }

  let(:node) {
    i2 = doctype.allocate
    i2.instance_variable_set(:@doc, doc.doc.children[0])
    i2
  }

  let(:doctype) { Pakyow::Presenter::NokogiriDoc }

  include_examples :doc_specs
  include_examples :scope_specs
  include_examples :attr_specs
  include_examples :repeating_specs
  include_examples :matching_specs
  include_examples :building_specs
end
