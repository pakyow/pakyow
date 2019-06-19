RSpec.describe "defining the same object twice" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      object :post do
        def foo
        end
      end

      object :post do
        def bar
        end
      end
    end
  end

  it "does not create a second object" do
    expect(Pakyow.apps.first.state(:object).count).to eq(1)
  end

  it "extends the first object" do
    expect(Pakyow.apps.first.state(:object)[0].instance_methods(false).count).to eq(2)
    expect(Pakyow.apps.first.state(:object)[0].instance_methods(false)).to include(:foo)
    expect(Pakyow.apps.first.state(:object)[0].instance_methods(false)).to include(:bar)
  end
end
