require_relative "./operations/creating"
require_relative "./operations/dropping"

RSpec.shared_examples :source_sql_operations do
  before do
    local_connection_type, local_connection_string = connection_type, connection_string

    Pakyow.after :configure do
      config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
    end
  end

  include_context "cli" do
    let :project_context do
      true
    end
  end

  include_context "app"

  let :autorun do
    false
  end

  it_behaves_like :source_operations_creating
  it_behaves_like :source_operations_dropping
end
