require_relative "./helpers"

RSpec.shared_examples :source_associations_has_many do |dependents: :raise|
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
          expect(results.one.send(association_name).count).to eq(1)
        end
      end

      context "no associated data exists" do
        before do
          target_dataset.create
        end

        it "includes an empty result" do
          expect(results.last.send(association_name)).to eq([])
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
            results.one.send(association_name).count
          ).to eq(1)

          expect(
            results.one.send(association_name)[0]
          ).to eq(associated_dataset.last)
        end
      end

      describe "including an association after updating" do
        before do
          target_dataset.create(
            association_name => associated_dataset.create
          )
        end

        let :results do
          target_dataset.update({}).including(association_name)
        end

        it "includes the associated data in each result" do
          results.each_with_index do |result, i|
            expect(
              result.send(association_name).count
            ).to eq(1)

            expect(
              result.send(association_name)[0]
            ).to eq(associated_dataset.at(i))
          end
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
        ).to eq([associated_new.one])
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
          ).to eq([associated_new.one])
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
        ).to eq([])
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
          ).to eq([])
        end
      end

      context "dataset includes more than one result" do
        def create
          target_dataset.create(
            association_name => associated_dataset
          )
        end

        it "associates each result" do
          associated_dataset.create
          associated_dataset.create

          expect {
            create
          }.to change {
            target_dataset.count
          }.by(1)

          expect(
            target_dataset.including(
              association_name
            ).last.send(association_name)
          ).to eq(associated_dataset.to_a)
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

      context "dataset is cached prior to creating" do
        def create
          associated_new.to_a
          target_dataset.create(
            association_name => associated_new
          )
        end

        it "invalidates the dataset" do
          create
          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)
          ).to eq([associated_new.one])
        end
      end
    end

    context "passing an array of associated objects" do
      before do
        associated_dataset.create
        associated_dataset.create
        associated_dataset.create
      end

      def create(objects = associated_dataset.to_a)
        target_dataset.create(
          association_name => objects
        )
      end

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
        ).to eq(associated_dataset.to_a)
      end

      it "updates the foreign key on each associated object" do
        objects = associated_dataset.to_a
        create(objects)
        objects.each do |object|
          expect(
            object.send(:"#{associated_as}_id")
          ).to eq(
            target_dataset.one.id
          )
        end
      end

      context "array includes an object that does not exist" do
        it "raises a constraint violation and does not create" do
          objects = associated_dataset.create.to_a
          associated_dataset.delete

          expect {
            target_dataset.create(
              association_name => objects
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value could not be found")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "array includes an object that originated from a different source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => data.unassociated.create.to_a
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value did not originate from #{associated_source}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "array includes an object that originated from an unknown source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => [Pakyow::Data::Object.new(id: 1)]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object with an unknown source as #{association_name}")
          end

          expect(
            target_dataset.count
          ).to be(0)
        end
      end

      context "array includes some other object" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => [{}]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value is not a Pakyow::Data::Object")
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

      it "raises a type mismatch and does not create" do
        expect {
          create
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("Cannot associate Pakyow::Data::Object as #{association_name}")
        end

        expect(
          target_dataset.count
        ).to be(0)
      end
    end

    context "passing an associated id" do
      def create
        target_dataset.create(
          association_name => associated_new.one.id
        )
      end

      it "raises a type mismatch and does not create" do
        expect {
          create
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("Cannot associate Integer as #{association_name}")
        end

        expect(
          target_dataset.count
        ).to be(0)
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
          target_dataset.including(association_name).one.send(association_name).map(&:id)
        }.from(
          associated_old.map(&:id)
        ).to(
          associated_new.map(&:id)
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
            target_dataset.including(association_name).one.send(association_name).map(&:id)
          }.from(
            associated_old.map(&:id)
          ).to(
            associated_new.map(&:id)
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
          ).one.send(association_name).map(&:id)
        }
      end
    end

    context "passing an associated dataset" do
      def update
        target_dataset.update(
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
            ).one.send(association_name).map(&:id)
          }.from(
            associated_old.map(&:id)
          ).to(
            []
          )
        end
      end

      context "dataset includes more than one result" do
        def update
          target_dataset.update(
            updatable: updated_value,
            association_name => associated_dataset
          )
        end

        it "associates each result" do
          associated_dataset.create
          associated_dataset.create

          expect {
            update
          }.to change {
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          }.from(
            associated_old.map(&:id)
          ).to(
            associated_dataset.to_a.map(&:id)
          )
        end
      end

      context "dataset is for a different source" do
        def update
          target_dataset.update(
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
            ).one.send(association_name).map(&:id)
          ).to eq(associated_old.map(&:id))

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "dataset is cached prior to updating" do
        def create
          associated_new.one
          target_dataset.update(
            updatable: updated_value,
            association_name => associated_new
          )
        end

        it "invalidates the dataset" do
          update
          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          ).to eq(associated_new.map(&:id))
        end
      end
    end

    context "passing an array of associated objects" do
      before do
        associated_dataset.create
        associated_dataset.create
        associated_dataset.create
      end

      def update(objects = associated_dataset.to_a)
        target_dataset.update(
          updatable: updated_value,
          association_name => objects
        )
      end

      it "updates" do
        expect {
          update
        }.to change {
          target_dataset.map(&:updatable)
        }.to([updated_value])
      end

      it "associates" do
        expect {
          update
        }.to change {
          target_dataset.including(
            association_name
          ).one.send(association_name).map(&:id)
        }.to(associated_dataset.map(&:id))
      end

      it "updates the foreign key on each associated object" do
        objects = associated_dataset.to_a
        update(objects)
        objects.each do |object|
          expect(
            object.send(:"#{associated_as}_id")
          ).to eq(
            target_dataset.one.id
          )
        end
      end

      context "array includes an object that does not exist" do
        it "raises a constraint violation and does not update" do
          objects = associated_dataset.create.to_a
          associated_dataset.delete

          expect {
            target_dataset.update(
              association_name => objects
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value could not be found")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          ).to eq(associated_old.map(&:id))

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "array includes an object that originated from a different source" do
        it "raises a type mismatch and does not update" do
          expect {
            target_dataset.update(
              association_name => data.unassociated.create.to_a
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value did not originate from #{associated_source}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          ).to eq(associated_old.map(&:id))

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "array includes an object that originated from an unknown source" do
        it "raises a type mismatch and does not update" do
          expect {
            target_dataset.update(
              association_name => [Pakyow::Data::Object.new(id: 1)]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate an object with an unknown source as #{association_name}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          ).to eq(associated_old.map(&:id))

          expect(
            target_dataset.one.updatable
          ).to eq(initial_value)
        end
      end

      context "array includes some other object" do
        it "raises a type mismatch and does not update" do
          expect {
            target_dataset.update(
              association_name => [{}]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("Cannot associate results as #{association_name} because at least one value is not a Pakyow::Data::Object")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&:id)
          ).to eq(associated_old.map(&:id))

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

      it "raises a type mismatch and does not update" do
        expect {
          update
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("Cannot associate Pakyow::Data::Object as #{association_name}")
        end

        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name).map(&:id)
        ).to eq(associated_old.map(&:id))

        expect(
          target_dataset.one.updatable
        ).to eq(initial_value)
      end
    end

    context "passing an associated id" do
      def update
        target_dataset.update(
          updatable: updated_value,
          association_name => associated_new.one.id
        )
      end

      it "raises a type mismatch and does not update" do
        expect {
          update
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("Cannot associate Integer as #{association_name}")
        end

        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name).map(&:id)
        ).to eq(associated_old.map(&:id))

        expect(
          target_dataset.one.updatable
        ).to eq(initial_value)
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

      it "raises a constraint violation and does not update"
    end
  end

  describe "deleting" do
    context "contains dependents" do
      before do
        target_dataset.create(
          association_name => associated_dataset.create
        )

        target_dataset.create
      end

      if dependents == :raise
        it "raises an error" do
          expect {
            target_dataset.delete
          }.to raise_error(Pakyow::Data::ConstraintViolation)
        end

        it "does not delete the data" do
          expect {
            begin
              target_dataset.delete
            rescue
            end
          }.to_not change {
            target_dataset.count
          }
        end
      elsif dependents == :delete
        it "deletes the data" do
          expect {
            target_dataset.delete
          }.to change {
            target_dataset.count
          }.by(target_dataset.count * -1)
        end

        it "deletes the dependent data" do
          expect {
            target_dataset.delete
          }.to change {
            associated_dataset.count
          }.by(-1)
        end

        it "does not delete non-dependent data" do
          associated_dataset.create
          associated_dataset.create
          associated_dataset.create

          expect {
            target_dataset.delete
          }.to change {
            associated_dataset.count
          }.by(-1)
        end

        context "dependent data errors on delete" do
          before do
            associated_dataset.source.class.class_eval do
              def delete
                raise RuntimeError
              end
            end
          end

          it "does not delete the data" do
            expect {
              begin
                target_dataset.delete
              rescue
              end
            }.not_to change {
              target_dataset.count
            }
          end

          it "does not delete the dependent data" do
            expect {
              begin
                target_dataset.delete
              rescue
              end
            }.not_to change {
              associated_dataset.count
            }
          end
        end
      elsif dependents == :nullify
        it "deletes the data" do
          expect {
            target_dataset.delete
          }.to change {
            target_dataset.count
          }.by(target_dataset.count * -1)
        end

        it "nullifies the related column on the dependent data" do
          expect {
            target_dataset.delete
          }.not_to change {
            associated_dataset.count
          }

          expect(associated_dataset.last[:"#{associated_as}_id"]).to be(nil)
        end

        it "does not nullify non-dependent data" do
          unassociated = associated_dataset.create(
            associated_as => target_dataset.create
          )

          expect {
            target_dataset.by_id(1).delete
          }.not_to change {
            associated_dataset.count
          }

          expect(associated_dataset.count > 0).to be(true)

          unassociated.each do |object|
            expect(object.send(:"#{associated_as}_id")).not_to be(nil)
          end
        end

        context "dependent data errors on delete" do
          before do
            associated_dataset.source.class.class_eval do
              def update(*)
                raise RuntimeError
              end
            end
          end

          it "does not delete the data" do
            expect {
              begin
                target_dataset.delete
              rescue
              end
            }.not_to change {
              target_dataset.count
            }
          end

          it "does not nullify the dependent data" do
            expect {
              begin
                target_dataset.by_id(1).delete
              rescue
              end
            }.not_to change {
              associated_dataset.count
            }

            expect(associated_dataset.count > 0).to be(true)

            associated_dataset.each do |object|
              expect(object.send(:"#{associated_as}_id")).not_to be(nil)
            end
          end
        end
      else
        raise "Unknown option for `dependents`: #{dependents.inspect}"
      end
    end

    context "without dependents" do
      before do
        target_dataset.create
      end

      it "does not raise an error" do
        target_dataset.delete
      end

      it "deletes the data" do
        target_dataset.delete
        expect(target_dataset.count).to eq(0)
      end
    end
  end

  describe "creating associated data" do
    before do
      target_dataset.create(
        association_name => associated_old
      )
    end

    let :associated_old do
      associated_dataset.create
    end

    let :associated_new do
      associated_dataset.create(
        associated_as => target_dataset.one
      )
    end

    def create
      associated_new
    end

    it "associates the new data" do
      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)

      create

      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_new.one)
    end

    it "does not remove the current assciation" do
      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)

      create

      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)
    end
  end

  describe "updating associated data" do
    before do
      target_dataset.create(
        association_name => associated_old
      )
    end

    let :associated_old do
      associated_dataset.create
    end

    let :associated_new do
      associated_dataset.create
    end

    def update
      associated_new.update(
        associated_as => target_dataset.one
      )
    end

    it "associates the new data" do
      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)

      update

      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_new.one)
    end

    it "does not remove the current assciation" do
      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)

      update

      expect(
        target_dataset.including(association_name).one.send(association_name)
      ).to include(associated_old.one)
    end
  end
end
