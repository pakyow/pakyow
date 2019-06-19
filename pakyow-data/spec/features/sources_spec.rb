RSpec.describe "defining the same source twice" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      source :posts do
        attribute :foo
      end

      source :posts do
        attribute :bar
      end
    end
  end

  it "does not create a second source" do
    expect(Pakyow.apps.first.state(:source).count).to eq(1)
  end

  it "includes the attribute from the first definition" do
    expect(Pakyow.apps.first.state(:source)[0].attributes.keys).to include(:foo)
  end

  it "includes the attribute from the second definition" do
    expect(Pakyow.apps.first.state(:source)[0].attributes.keys).to include(:bar)
  end
end
