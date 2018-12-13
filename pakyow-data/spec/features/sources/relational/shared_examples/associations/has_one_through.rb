require_relative "./helpers"
require_relative "./one_to_one"

RSpec.shared_examples :source_associations_has_one_through do |dependents: :raise|
  it_behaves_like :source_associations_has_one, dependents: dependents, one_to_one: true

  describe "relationship with the joining source" do
    it_behaves_like :source_associations_has_one, dependents: dependents do
      let :associated_source do
        joining_source
      end

      let :association_name do
        Pakyow::Support.inflector.singularize(joining_source).to_sym
      end

      let :associated_as do
        Pakyow::Support.inflector.singularize(super()).to_sym
      end
    end

    describe "reciprocal relationship" do
      it_behaves_like :source_associations_belongs_to, dependents: dependents do
        let :target_source do
          joining_source
        end

        let :associated_source do
          # Return the target source from the parent context. It's buried in
          # the ancestry list, so this is the most reliable way I could come up
          # with to predictably find the value. If we don't do this we just return
          # self's target_source, which is incorrect.
          #
          self.class.ancestors.select { |ancestor|
            ancestor.instance_methods.include?(:target_source)
          }.map { |ancestor|
            ancestor.instance_method(:target_source).bind(self).call
          }.find { |value|
            value != target_source
          }
        end

        let :association_name do
          Pakyow::Support.inflector.singularize(associated_as).to_sym
        end
      end
    end
  end
end
