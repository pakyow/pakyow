require_relative "./helpers"
require_relative "./has_many"

RSpec.shared_examples :source_associations_many_to_many do |dependents: :raise|
  it_behaves_like :source_associations_has_many, dependents: dependents, many_to_many: true

  describe "foreign keys" do
    include_context :source_associations_helpers

    it "does not create foreign keys on the target source" do
      expect(target_dataset.source.class.attributes.keys).not_to include(left_join_key)
      expect(target_dataset.source.class.attributes.keys).not_to include(right_join_key)
    end

    it "does not create foreign keys on the associated source" do
      expect(associated_dataset.source.class.attributes.keys).not_to include(left_join_key)
      expect(associated_dataset.source.class.attributes.keys).not_to include(right_join_key)
    end
  end
end
