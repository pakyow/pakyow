RSpec.shared_context "cli" do
  before do
    require "pakyow/cli"
    allow(Pakyow::CLI).to receive(:project_context?).and_return(project_context)
  end

  let :project_context do
    false
  end
end
