require "pakyow/assets/precompiler"

RSpec.describe "assets:precompile" do
  let :precompiler_instance do
    double(:precompiler).as_null_object
  end

  let :app do
    double(:app)
  end

  before do
    require "pakyow/task"
    @loader = Pakyow::Task::Loader.new(File.expand_path("../../../../lib/pakyow/tasks/assets/precompile.rake", __FILE__))
    allow(Pakyow::Assets::Precompiler).to receive(:new).and_return(precompiler_instance)
  end

  after do
    task = @loader.__tasks.first
    task.call(app: app)
  end

  it "initializes the precompiler" do
    expect(Pakyow::Assets::Precompiler).to receive(:new).with(app).and_return(precompiler_instance)
  end

  it "invokes the precompiler" do
    expect(precompiler_instance).to receive(:precompile!)
  end
end
