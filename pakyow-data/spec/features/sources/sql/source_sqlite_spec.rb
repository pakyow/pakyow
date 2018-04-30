require_relative "../shared_examples/associations"
require_relative "../shared_examples/commands"
require_relative "../shared_examples/connection"
require_relative "../shared_examples/queries"
require_relative "../shared_examples/qualifications"
require_relative "../shared_examples/results"
require_relative "../shared_examples/schema"

RSpec.describe "sqlite source" do
  include_examples :source_associations
  include_examples :source_commands
  include_examples :source_connection
  include_examples :source_queries
  include_examples :source_qualifications
  include_examples :source_results
  include_examples :source_schema

  let :connection_string do
    "sqlite::memory"
  end

  describe "sqlite-specific types" do
    it "needs to be defined"
  end
end
