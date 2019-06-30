RSpec.shared_context :source_associations_helpers do
  before do
    local_association_primary_key_field = association_primary_key_field
    unknown_value = case association_primary_key_type
    when :integer
      12321
    when :string
      "foo"
    end

    associated_dataset.source.class.send(:define_method, :return_none) do
      source_from_self(
        where(local_association_primary_key_field => unknown_value)
      )
    end
  end

  let :app_def do
    super_app_definition = super()
    spec_context = self

    Proc.new do
      instance_exec(&super_app_definition)

      source :unassociated do
        primary_id

        query do
          order(id: :asc)
        end
      end

      object :special do
      end

      after "initialize", priority: :high do
        # Define an updatable attribute on the source.
        #
        state(:source).find { |instance|
          instance.__object_name.name == spec_context.target_source
        }.class_eval do
          attribute :updatable
        end
      end
    end
  end

  let :foreign_key do
    :"#{association_name}_#{association_primary_key_field}"
  end

  let :primary_key_field do
    target_dataset.source.class.primary_key_field
  end

  let :association_primary_key_field do
    associated_dataset.source.class.primary_key_field
  end

  let :association_primary_key_type do
    associated_dataset.source.class.primary_key_type
  end

  let :joining_source do
    if defined?(super())
      super()
    else
      [target_source, associated_source].sort.join("_").to_sym
    end
  end

  let :left_join_key do
    :"#{Pakyow::Support.inflector.singularize(associated_as)}_#{primary_key_field}"
  end

  let :right_join_key do
    :"#{Pakyow::Support.inflector.singularize(association_name)}_#{association_primary_key_field}"
  end

  def target_dataset
    data.send(target_source)
  end

  def associated_dataset
    data.send(associated_source)
  end

  def joining_dataset
    data.send(joining_source)
  end
end
