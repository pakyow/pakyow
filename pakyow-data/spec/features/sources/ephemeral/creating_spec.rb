RSpec.describe "creating an ephemeral data source" do
  include_context "testable app"

  let :data do
    Pakyow.apps.first.data
  end

  it "creates an ephemeral data object wrapped in a proxy" do
    expect(data.ephemeral(:test)).to be_instance_of(Pakyow::Data::Proxy)
    expect(data.ephemeral(:test).source).to be_instance_of(Pakyow::Data::Sources::Ephemeral)
  end

  it "can be created with a type" do
    expect(data.ephemeral(:test).type).to eq(:test)
  end

  it "can be created with explicit qualifications" do
    expect(data.ephemeral(:test, id: "123").source.qualifications).to eq(id: "123", type: :test)
  end

  it "can have a value set on it" do
    expect(data.ephemeral(:test).set([value: "foo"]).one[:value]).to eq("foo")
  end
end
