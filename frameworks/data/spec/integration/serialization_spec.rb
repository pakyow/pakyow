RSpec.describe "serializing proxies" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      source :posts do
        attribute :title, :string
      end
    end
  end

  context "result method is called on the proxy" do
    it "does not deserialize as a result" do
      proxy = Pakyow.app(:test).data.posts
      proxy.count

      deserialized = Marshal.load(Marshal.dump(proxy))
      expect(deserialized).to be_instance_of(Pakyow::Data::Proxy)
    end
  end
end

RSpec.describe "serializing results" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      source :posts do
        attribute :title, :string
      end
    end
  end

  it "deserializes as a result" do
    result = Pakyow.app(:test).data.posts.count
    deserialized = Marshal.load(Marshal.dump(result))
    expect(deserialized).to be_instance_of(Pakyow::Data::Result)
    expect(deserialized).to eq(0)
  end
end
