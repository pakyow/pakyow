RSpec.describe "assets prelaunch tasks" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
    end
  end

  it "registers assets:precompile on the app" do
    expect(Pakyow.apps.first.config.tasks.prelaunch).to include([:"assets:precompile", {}])
  end
end
