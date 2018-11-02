require_relative "./associations/belongs_to"
require_relative "./associations/has_many"
require_relative "./associations/has_one"

RSpec.shared_examples :source_associations do
  describe "associating sources" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    include_examples :source_associations_belongs_to
    include_examples :source_associations_has_many
    include_examples :source_associations_has_one

    describe "has_many :through" do
      it "will be supported in the future"
    end

    describe "has_one :through" do
      it "will be supported in the future"
    end

    describe "many_to_many" do
      it "will be supported in the future"
    end
  end
end
