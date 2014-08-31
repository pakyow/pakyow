require_relative 'support/helper'

describe NokogiriDoc do
  let(:doc) { doctype.new(html) }

  let(:node) {
    i2 = doctype.allocate
    i2.instance_variable_set(:@doc, doc.doc.children[0])
    i2
  }

  let(:doctype) { NokogiriDoc }

  include_examples :doc_specs
  include_examples :scope_specs
  include_examples :attr_specs
end
