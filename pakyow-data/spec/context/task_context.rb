RSpec.shared_context "task" do
  before do
    @old_environment_tasks = Pakyow.config.tasks.paths.dup
    Pakyow.config.tasks.paths.delete("./tasks")
    Pakyow.load_tasks
  end

  after do
    Pakyow.config.tasks.paths = @old_environment_tasks
  end
end
