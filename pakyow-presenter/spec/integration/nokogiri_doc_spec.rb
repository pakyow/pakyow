require_relative 'support/int_helper'

describe Pakyow::Presenter::NokogiriDoc do
  def node_from_doc(doc)
    i2 = doctype.allocate
    i2.instance_variable_set(:@doc, doc.doc.children[0])
    i2
  end

  let :doctype do
    Pakyow::Presenter::NokogiriDoc
  end

  include_examples :doc_specs
  include_examples :scope_specs
  include_examples :attr_specs
  include_examples :repeating_specs
  include_examples :matching_specs
  include_examples :building_specs
end
