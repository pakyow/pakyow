RSpec.describe "environment data connections config" do
  before do
    Pakyow.setup
  end

  let :config do
    Pakyow.config.data.connections
  end

  it "has a setting for each type" do
    Pakyow::Data::Connection.adapter_types.each do |type|
      expect(config.public_send(type)).to be_instance_of(Hash)
    end
  end
end
