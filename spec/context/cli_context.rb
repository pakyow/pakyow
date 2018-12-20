RSpec.shared_context "cli" do
  before do
    require "pakyow/cli"
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(project_context)

    @old_environment_tasks = Pakyow.config.tasks.paths.dup
    Pakyow.config.tasks.paths.delete("./tasks")
  end

  after do
    Pakyow.config.tasks.paths = @old_environment_tasks
  end

  let :project_context do
    false
  end
end
