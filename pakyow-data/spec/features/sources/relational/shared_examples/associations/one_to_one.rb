require_relative "./helpers"
require_relative "./has_one"

RSpec.shared_examples :source_associations_one_to_one do |dependents: :raise|
  include_context :source_associations_helpers

  it_behaves_like :source_associations_has_one, one_to_one: true
end
