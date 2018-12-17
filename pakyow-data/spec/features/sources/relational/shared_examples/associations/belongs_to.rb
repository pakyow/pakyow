require_relative "./helpers"

RSpec.shared_examples :source_associations_belongs_to do
  include_context :source_associations_helpers

  describe "querying" do
    before do
      target_dataset.create(
        association_name => associated_dataset.create
      )
    end

    context "without including the association" do
      let :results do
        target_dataset
      end

      it "does not include the associated data" do
        expect(results.one).to_not respond_to(association_name)
      end
    end

    context "including the association" do
      let :results do
        target_dataset.including(association_name)
      end

      it "includes the associated data" do
        expect(results.one.send(association_name)).to_not be(nil)
      end

      context "included association does not exist" do
        it "raises an error" do
          expect {
            target_dataset.including(:nonexistent)
          }.to raise_error(Pakyow::Data::UnknownAssociation) do |error|
            expect(error.context.ancestors).to include(Pakyow::Data::Sources::Relational)
            expect(error.message).to include("Unknown association `nonexistent`")
          end
        end
      end

      context "data associated to another object exists" do
        before do
          target_dataset.create(
            association_name => associated_dataset.create
          )
        end

        it "does not include unassociated data" do
          expect(
            results.one.send(association_name)[association_primary_key_field]
          ).to eq(
            associated_dataset.to_a.first[association_primary_key_field]
          )
        end
      end

      context "no associated data exists" do
        before do
          target_dataset.create
        end

        it "includes an empty result" do
          expect(results.last.send(association_name)).to be(nil)
        end
      end

      describe "including an association after creating" do
        let :results do
          target_dataset.create(
            association_name => associated_dataset.create
          ).including(association_name)
        end

        it "includes the associated data in the result" do
          expect(
            results.one.send(association_name)[association_primary_key_field]
          ).to eq(
            associated_dataset.to_a.last[association_primary_key_field]
          )
        end
      end

      describe "including an association after updating" do
        before do
          target_dataset.create(
            association_name => associated_dataset.create
          )
        end

        let :results do
          target_dataset.update.including(association_name)
        end

        it "includes the associated data in the result" do
          expect(
            results.last.send(association_name)[association_primary_key_field]
          ).to eq(
            associated_dataset.to_a.last[association_primary_key_field]
          )
        end
      end
    end
  end

  describe "creating" do
    shared_examples :common do
      it "creates" do
        expect {
          create
        }.to change {
          target_dataset.count
        }.by(1)
      end

      it "associates" do
        create
        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name)
        ).to eq(associated_new.one)
      end

      context "other data exists that could be associated" do
        before do
          associated_dataset.create
          create
          associated_dataset.create
          associated_dataset.create
        end

        it "associates the specified data" do
          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)
          ).to eq(associated_new.one)
        end
      end
    end

    let :associated_new do
      associated_dataset.create
    end

    context "without associated data" do
      def create
        target_dataset.create
      end

      it "creates" do
        expect {
          create
        }.to change {
          target_dataset.count
        }.by(1)
      end

      it "does not associate" do
        create
        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name)
        ).to be(nil)
      end
    end

    context "passing an associated dataset" do
      def create
        target_dataset.create(
          association_name => associated_new
        )
      end

      include_examples :common

      context "dataset includes no results" do
        before do
          target_dataset.create(
            association_name => associated_dataset.return_none
          )
        end

        it "does not associate" do
          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)
          ).to be(nil)
        end
      end

      context "dataset includes more than one result" do
        it "raises a constraint violation and does not create" do
          associated_dataset.create
          associated_dataset.create

          expect {
            target_dataset.create(
              association_name => associated_dataset
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate multiple results as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "dataset is for a different source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => data.unassociated.create
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate unassociated as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end
    end

    context "passing an associated object" do
      def create
        target_dataset.create(
          association_name => associated_new.one
        )
      end

      include_examples :common

      context "passed an object that does not exist" do
        it "raises a constraint violation and does not create" do
          object = associated_dataset.create.one
          associated_dataset.delete

          expect {
            target_dataset.create(
              association_name => object
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot find associated #{association_name} with #{association_primary_key_field} of #{object[association_primary_key_field]}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed an object that originated from a different source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => data.unassociated.create.one
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object from unassociated as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed an object that originated from an unknown source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => Pakyow::Data::Object.new(id: 1)
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object with an unknown source as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed an array" do
        it "raises a constraint violation and does not create" do
          expect {
            target_dataset.create(
              association_name => []
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate multiple results as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed some other object" do
        it "raises a type mismatch and does not create" do
          type = Class.new

          expect {
            target_dataset.create(
              association_name => type.new
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate #{type} as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end
    end

    context "passing an associated id" do
      def create
        target_dataset.create(
          foreign_key => associated_new.one[association_primary_key_field]
        )
      end

      include_examples :common

      context "passed a foreign key that does not exist" do
        it "raises a constraint violation and does not create" do
          expect {
            target_dataset.create(
              foreign_key => 123
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot find associated #{association_name} with #{association_primary_key_field} of 123")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed a foreign key that is not a foreign key" do
        it "raises an error and does not create" do
          error_type = case association_primary_key_type
          when :string
            Pakyow::Data::ConstraintViolation
          else
            Pakyow::Data::TypeMismatch
          end

          expect {
            target_dataset.create(
              foreign_key => true
            )
          }.to raise_error(error_type)

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed an object as a foreign key" do
        it "raises an error and does not create" do
          expect {
            target_dataset.create(
              foreign_key => associated_dataset.create.one
            )
          }.to raise_error(Pakyow::Data::TypeMismatch)

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "passed a dataset as an foreign key" do
        it "raises an error and does not create" do
          expect {
            target_dataset.create(
              foreign_key => associated_dataset.create
            )
          }.to raise_error(Pakyow::Data::TypeMismatch)

          expect(
            target_dataset.count
          ).to be(0)
        end
      end
    end
  end

  describe "updating" do
    shared_examples :common do
      it "updates" do
        expect {
          update
        }.to change {
          target_dataset.one.updatable
        }.from(initial_value).to(updated_value)
      end

      it "associates" do
        expect {
          update
        }.to change {
          target_dataset.including(association_name).one.send(association_name)[association_primary_key_field]
        }.from(
          associated_old.one[association_primary_key_field]
        ).to(
          associated_new.one[association_primary_key_field]
        )
      end

      context "other data exists that could be associated" do
        before do
          associated_dataset.create
          associated_dataset.create
          associated_dataset.create
        end

        it "associates the specified data" do
          expect {
            update
          }.to change {
            target_dataset.including(association_name).one.send(association_name)[association_primary_key_field]
          }.from(
            associated_old.one[association_primary_key_field]
          ).to(
            associated_new.one[association_primary_key_field]
          )
        end
      end
    end

    before do
      # Create the updatable object with a currently associated object.
      #
      target_dataset.create(
        updatable: initial_value,
        association_name => associated_old
      )
    end

    let :initial_value do
      "initial"
    end

    let :updated_value do
      SecureRandom.hex
    end

    let :associated_old do
      associated_dataset.create
    end

    let :associated_new do
      associated_dataset.create
    end

    context "without associated data" do
      def update
        target_dataset.update(
          updatable: updated_value
        )
      end

      it "updates" do
        expect {
          update
        }.to change {
          target_dataset.one.updatable
        }.from(initial_value).to(updated_value)
      end

      it "does not lose the current association" do
        expect {
          update
        }.not_to change {
          target_dataset.including(
            association_name
          ).one.send(association_name)[association_primary_key_field]
        }
      end
    end

    context "passing an associated dataset" do
      def update
        target_dataset.by_id(1).update(
          updatable: updated_value,
          association_name => associated_new
        )
      end

      include_examples :common

      context "dataset includes no results" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => associated_new.return_none
          )
        end

        it "removes the current association" do
          expect {
            update
          }.to change {
            target_dataset.including(
              association_name
            ).one.send(association_name)&.send(association_primary_key_field)
          }.from(
            associated_old.one[association_primary_key_field]
          ).to(
            nil
          )
        end
      end

      context "dataset includes more than one result" do
        def update
          target_dataset.by_id(1).update(
            updatable: updated_value,
            association_name => associated_dataset
          )
        end

        it "raises a constraint violation and does not update" do
          associated_dataset.create
          associated_dataset.create

          expect {
            update
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate multiple results as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "dataset is for a different source" do
        def update
          target_dataset.by_id(1).update(
            updatable: updated_value,
            association_name => data.unassociated.create
          )
        end

        it "raises a type mismatch and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate unassociated as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end
    end

    context "passing an associated object" do
      def update
        target_dataset.update(
          updatable: updated_value,
          association_name => associated_new.one
        )
      end

      include_examples :common

      context "passing nil" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => nil
          )
        end

        it "updates" do
          expect {
            update
          }.to change {
            target_dataset.one.updatable
          }.from(initial_value).to(updated_value)
        end

        it "removes the current association" do
          expect {
            update
          }.to change {
            target_dataset.including(
              association_name
            ).one.send(association_name)&.send(association_primary_key_field)
          }.from(
            associated_old.one[association_primary_key_field]
          ).to(
            nil
          )
        end
      end

      context "passed an object that does not exist" do
        def update
          associated_dataset.send(:"by_#{association_primary_key_field}", object[association_primary_key_field]).delete

          target_dataset.update(
            updatable: updated_value,
            association_name => object
          )
        end

        let :object do
          associated_new.one
        end

        it "raises a constraint violation and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot find associated #{association_name} with #{association_primary_key_field} of #{object[association_primary_key_field]}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed an object that originated from a different source" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => data.unassociated.create.one
          )
        end

        it "raises a type mismatch and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object from unassociated as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "object is from an unknown source" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => Pakyow::Data::Object.new(id: 1)
          )
        end

        it "raises a type mismatch and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object with an unknown source as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed an array" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => []
          )
        end

        it "raises a constraint violation and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate multiple results as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed some other object" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => {}
          )
        end

        it "raises a type mismatch and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate Hash as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end
    end

    context "passing an associated id" do
      def update
        target_dataset.update(
          updatable: updated_value,
          foreign_key => associated_new.one[association_primary_key_field]
        )
      end

      include_examples :common

      context "passing nil" do
        def update
          target_dataset.update(
            updatable: updated_value,
            foreign_key => nil
          )
        end

        it "updates" do
          expect {
            update
          }.to change {
            target_dataset.one.updatable
          }.from(initial_value).to(updated_value)
        end

        it "removes the current association" do
          expect {
            update
          }.to change {
            target_dataset.including(
              association_name
            ).one.send(association_name)&.send(association_primary_key_field)
          }.from(
            associated_old.one[association_primary_key_field]
          ).to(
            nil
          )
        end
      end

      context "passed a foreign key that does not exist" do
        def update
          target_dataset.update(
            updatable: updated_value,
            foreign_key => 123
          )
        end

        it "raises a constraint violation and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot find associated #{association_name} with #{association_primary_key_field} of 123")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed a foreign key that is not of the correct type" do
        def update
          target_dataset.update(
            updatable: updated_value,
            foreign_key => true
          )
        end

        it "raises an error and does not update" do
          error_type = case association_primary_key_type
          when :string
            Pakyow::Data::ConstraintViolation
          else
            Pakyow::Data::TypeMismatch
          end

          expect {
            update
          }.to raise_error(error_type)

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed an object as a foreign key" do
        def update
          target_dataset.update(
            updatable: updated_value,
            foreign_key => associated_dataset.create.one
          )
        end

        it "raises an error and does not update" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch)

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "passed a dataset as a foreign key" do
        def update
          target_dataset.update(
            updatable: updated_value,
            foreign_key => associated_dataset.create
          )
        end

        it "raises an error and does not create" do
          expect {
            update
          }.to raise_error(Pakyow::Data::TypeMismatch)

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)[association_primary_key_field]
          ).to eq(associated_old.one[association_primary_key_field])

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end
    end

    context "multiple objects are updated with associated data" do
      before do
        2.times do
          target_dataset.create(
            updatable: initial_value,
            association_name => associated_old
          )
        end
      end

      def update
        target_dataset.update(
          updatable: updated_value,
          association_name => associated_new
        )
      end

      it "raises a constraint violation and does not update" do
        expect {
          update
        }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
          expect(error.message).to eq("Cannot associate multiple results as #{association_name}")
        end

        expect(
          target_dataset.map(&:updatable)
        ).to eq([initial_value, initial_value, initial_value])
      end
    end
  end

  describe "deleting" do
    before do
      target_dataset.create(
        association_name => associated_dataset.create
      )
    end

    it "deletes the data" do
      expect {
        target_dataset.delete
      }.to change {
        target_dataset.count
      }.by(target_dataset.count * -1)
    end

    it "does not delete the associated data" do
      expect {
        target_dataset.delete
      }.not_to change {
        associated_dataset.count
      }
    end
  end

  describe "foreign key" do
    before do
      target_dataset.create(
        association_name => associated_dataset.create
      )
    end

    let :foreign_key do
      target_dataset.source.class.container.connection.adapter.connection.schema(
        target_dataset.source.class.__object_name.name
      )[2][1]
    end

    it "is named appropriately" do
      expect(
        target_dataset.one.values.keys
      ).to include(:"#{association_name}_#{association_primary_key_field}")
    end
  end
end
