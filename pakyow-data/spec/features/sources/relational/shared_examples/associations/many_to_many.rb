require_relative "./helpers"
require_relative "./has_many"

RSpec.shared_examples :source_associations_many_to_many do |dependents: :raise|
  include_context :source_associations_helpers

  it_behaves_like :source_associations_has_many, many_to_many: true
end
