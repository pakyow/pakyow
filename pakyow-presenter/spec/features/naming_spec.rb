RSpec.describe "presenter name" do
  include_context "app"

  context "presenter is root" do
    let :app_def do
      Proc.new do
        presenter "/" do
        end
      end
    end

    it "has the expected value" do
      expect(Pakyow.apps[0].state(:presenter)[0].name).to eq("Test::Presenters::Index")
    end
  end

  context "presenter is not root" do
    let :app_def do
      Proc.new do
        presenter "/foo" do
        end
      end
    end

    it "has the expected value" do
      expect(Pakyow.apps[0].state(:presenter)[0].name).to eq("Test::Presenters::Foo")
    end
  end

  context "presenter is oddly named" do
    let :app_def do
      Proc.new do
        presenter "/foo/bar-baz" do
        end
      end
    end

    it "has the expected value" do
      expect(Pakyow.apps[0].state(:presenter)[0].name).to eq("Test::Presenters::Foo::BarBaz")
    end
  end
end
