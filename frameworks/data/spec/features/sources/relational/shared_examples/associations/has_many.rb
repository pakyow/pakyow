require_relative "./helpers"

RSpec.shared_examples :source_associations_has_many do |dependents: :raise, many_to_many: false|
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

      if many_to_many
        context "multiple objects are associated" do
          before do
            target_dataset.create(
              association_name => [
                associated_dataset.create.one,
                associated_dataset.create.one,
                associated_dataset.create.one
              ]
            )
          end

          it "includes all the associated data" do
            expect(
              results[0][association_name]
            ).to eq(
              [associated_dataset[0]]
            )

            expect(
              results[1][association_name]
            ).to eq(
              [
                associated_dataset[1],
                associated_dataset[2],
                associated_dataset[3]
              ]
            )
          end
        end

        context "multiple objects are associated, with overlap" do
          before do
            associated_dataset.create
            associated_dataset.create
            associated_dataset.create

            target_dataset.create(
              association_name => associated_dataset
            )
          end

          it "includes all the associated data" do
            expect(
              results[0][association_name]
            ).to eq(
              [associated_dataset[0]]
            )

            expect(
              results[1][association_name]
            ).to eq(
              associated_dataset.to_a
            )
          end
        end
      end

      context "included association does not exist" do
        it "raises an error" do
          expect {
            target_dataset.including(:nonexistent)
          }.to raise_error(Pakyow::Data::UnknownAssociation) do |error|
            expect(error.context.ancestors).to include(Pakyow::Data::Sources::Relational)
            expect(error.message).to include("unknown association `nonexistent'")
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
          target_dataset.update.including(association_name)
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
            expect(error.message).to eq("can't associate unassociated as `#{association_name}'")
          end

          expect(
            target_dataset.count
          ).to eq(0)
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

      unless many_to_many
        it "updates the foreign key on each associated object" do
          objects = associated_dataset.to_a
          create(objects)
          objects.each do |object|
            expect(
              object.send(:"#{associated_as}_#{primary_key_field}")
            ).to eq(
              target_dataset.one[primary_key_field]
            )
          end
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
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value could not be found")
          end

          expect(
            target_dataset.count
          ).to eq(0)
        end
      end

      context "array includes an object that originated from a different source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => data.unassociated.create.to_a
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value did not originate from #{associated_source}")
          end

          expect(
            target_dataset.count
          ).to eq(0)
        end
      end

      context "array includes an object that originated from an unknown source" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => [Pakyow::Data::Object.new(id: 1)]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("can't associate an object with an unknown source as `#{association_name}'")
          end

          expect(
            target_dataset.count
          ).to eq(0)
        end
      end

      context "array includes some other object" do
        it "raises a type mismatch and does not create" do
          expect {
            target_dataset.create(
              association_name => [{}]
            )
          }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value is not a Pakyow::Data::Object")
          end

          expect(
            target_dataset.count
          ).to eq(0)
        end
      end

      context "array originated from an update command" do
        it "associates" do
          target_dataset.create(
            association_name => associated_dataset.update.to_a
          )

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name)
          ).to eq(associated_dataset.to_a)
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
          expect(error.message).to eq("can't associate Pakyow::Data::Object as `#{association_name}'")
        end

        expect(
          target_dataset.count
        ).to eq(0)
      end
    end

    context "passing an associated id" do
      def create
        target_dataset.create(
          association_name => associated_new.one[association_primary_key_field]
        )
      end

      it "raises a type mismatch and does not create" do
        expect {
          create
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("can't associate #{associated_new.one[association_primary_key_field].class} as `#{association_name}'")
        end

        expect(
          target_dataset.count
        ).to eq(0)
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
          target_dataset.including(association_name).one.send(association_name).map(&association_primary_key_field)
        }.from(
          associated_old.map(&association_primary_key_field)
        ).to(
          associated_new.map(&association_primary_key_field)
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
            target_dataset.including(association_name).one.send(association_name).map(&association_primary_key_field)
          }.from(
            associated_old.map(&association_primary_key_field)
          ).to(
            associated_new.map(&association_primary_key_field)
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
          ).one.send(association_name).map(&association_primary_key_field)
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
            ).one.send(association_name).map(&association_primary_key_field)
          }.from(
            associated_old.map(&association_primary_key_field)
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
            ).one.send(association_name).map(&association_primary_key_field).sort
          }.from(
            associated_old.map(&association_primary_key_field).sort
          ).to(
            associated_dataset.to_a.map(&association_primary_key_field).sort
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
            expect(error.message).to eq("can't associate unassociated as `#{association_name}'")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_old.map(&association_primary_key_field))

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
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_new.map(&association_primary_key_field))
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
          ).one.send(association_name).map(&association_primary_key_field)
        }.to(associated_dataset.map(&association_primary_key_field))
      end

      unless many_to_many
        it "updates the foreign key on each associated object" do
          objects = associated_dataset.to_a
          update(objects)
          objects.each do |object|
            expect(
              object.send(:"#{associated_as}_#{primary_key_field}")
            ).to eq(
              target_dataset.one[primary_key_field]
            )
          end
        end
      end

      context "array includes an object that does not exist" do
        it "raises a constraint violation and does not update" do
          objects = associated_dataset.create.to_a

          objects.each do |object|
            associated_dataset.send(
              :"by_#{association_primary_key_field}",
              object[association_primary_key_field]
            ).delete
          end

          expect {
            target_dataset.update(
              association_name => objects
            )
          }.to raise_error(Pakyow::Data::ConstraintViolation) do |error|
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value could not be found")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_old.map(&association_primary_key_field))

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
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value did not originate from #{associated_source}")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_old.map(&association_primary_key_field))

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
            expect(error.message).to eq("can't associate an object with an unknown source as `#{association_name}'")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_old.map(&association_primary_key_field))

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
            expect(error.message).to eq("can't associate results as `#{association_name}' because at least one value is not a Pakyow::Data::Object")
          end

          expect(
            target_dataset.including(
              association_name
            ).one.send(association_name).map(&association_primary_key_field)
          ).to eq(associated_old.map(&association_primary_key_field))

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
          expect(error.message).to eq("can't associate Pakyow::Data::Object as `#{association_name}'")
        end

        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name).map(&association_primary_key_field)
        ).to eq(associated_old.map(&association_primary_key_field))

        expect(
          target_dataset.one.updatable
        ).to eq(initial_value)
      end
    end

    context "passing an associated id" do
      def update
        target_dataset.update(
          updatable: updated_value,
          association_name => associated_new.one[association_primary_key_field]
        )
      end

      it "raises a type mismatch and does not update" do
        expect {
          update
        }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
          expect(error.message).to eq("can't associate #{associated_new.one[association_primary_key_field].class} as `#{association_name}'")
        end

        expect(
          target_dataset.including(
            association_name
          ).one.send(association_name).map(&association_primary_key_field)
        ).to eq(associated_old.map(&association_primary_key_field))

        expect(
          target_dataset.one.updatable
        ).to eq(initial_value)
      end
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

        it "does not delete the dependent data" do
          expect {
            target_dataset.delete
          }.not_to change {
            associated_dataset.count
          }
        end

        if many_to_many
          it "nullifies the related column on the joining data" do
            target_dataset.delete
            expect(joining_dataset.last[left_join_key]).to be(nil)
          end

          it "does not nullify the other column on the joining data" do
            target_dataset.delete
            expect(joining_dataset.last[right_join_key]).to_not be(nil)
          end
        else
          it "nullifies the related column on the dependent data" do
            target_dataset.delete
            expect(associated_dataset.last[:"#{associated_as}_#{primary_key_field}"]).to be(nil)
          end

          it "does not nullify non-dependent data" do
            unassociated = associated_dataset.create(
              associated_as => target_dataset.create
            )

            target_dataset.send(:"by_#{primary_key_field}", 1).delete

            unassociated.each do |object|
              expect(object.send(:"#{associated_as}_#{primary_key_field}")).not_to be(nil)
            end
          end
        end

        context "dependent data errors on delete" do
          before do
            data.sources.values.each do |source|
              source.class_eval do
                def update(*)
                  raise RuntimeError
                end
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

            expect(associated_dataset.count > 0).to be(true)
          end

          if many_to_many
            it "does not nullify the joining data" do
              begin
                target_dataset.send(:"by_#{primary_key_field}", 1).delete
              rescue
              end

              joining_dataset.each do |object|
                expect(object[left_join_key]).not_to be(nil)
                expect(object[right_join_key]).not_to be(nil)
              end
            end
          else
            it "does not nullify the dependent data" do
              begin
                target_dataset.send(:"by_#{primary_key_field}", 1).delete
              rescue
              end

              associated_dataset.each do |object|
                expect(object.send(:"#{associated_as}_#{primary_key_field}")).not_to be(nil)
              end
            end
          end
        end
      else
        raise "unknown option for `dependents`: #{dependents.inspect}"
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
        associated_as => target_dataset
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

    it "does not remove the current association" do
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
        associated_as => target_dataset
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

    it "does not remove the current association" do
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
