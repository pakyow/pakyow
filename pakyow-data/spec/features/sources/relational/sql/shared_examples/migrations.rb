require_relative "./migrations/adding"
require_relative "./migrations/changing"
require_relative "./migrations/creating"
require_relative "./migrations/removing"

RSpec.shared_examples :source_sql_migrations do |adapter:|
  require "pakyow/data/adapters/sql"
  types = Pakyow::Data::Types::MAPPING.merge(
    Pakyow::Data::Adapters::Sql.types_for_adapter(
      adapter
    )
  ).reject { |type|
    # We don't care about primary key types here.
    #
    type.to_s.start_with?("pk_")
  }

  def migrator
    Pakyow::Data::Adapters::Sql::Migrator.new(connection)
  end

  let :additional_finalized_columns do
    ""
  end

  let :additional_finalized_columns_for_adding do
    ""
  end

  let :additional_finalized_columns_for_changing do
    ""
  end

  let :additional_finalized_columns_for_creating do
    ""
  end

  let :additional_initial_columns_for_removing do
    ""
  end

  let :additional_finalized_columns_for_removing do
    ""
  end

  before do
    local_connection_type, local_connection_string = connection_type, connection_string

    Pakyow.after :configure do
      config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
    end

    Pakyow.config.data.auto_migrate = false

    setup; Pakyow.boot
  end

  include_context "cli" do
    let :project_context do
      true
    end
  end

  include_context "migration"
  include_context "app"

  let :autorun do
    false
  end

  it_behaves_like :source_migrations_adding, types: types do
    let :additional_finalized_columns do
      additional_finalized_columns_for_adding
    end
  end

  it_behaves_like :source_migrations_changing, adapter: adapter, types: types do
    let :additional_finalized_columns do
      additional_finalized_columns_for_changing
    end
  end

  it_behaves_like :source_migrations_creating, types: types do
    let :additional_finalized_columns do
      additional_finalized_columns_for_creating
    end
  end

  # TODO: revisit this when we're ready to tackle all the edge cases
  #
  # it_behaves_like :source_migrations_removing, types: types do
  #   let :additional_initial_columns do
  #     additional_initial_columns_for_removing
  #   end

  #   let :additional_finalized_columns do
  #     additional_finalized_columns_for_removing
  #   end
  # end
end
