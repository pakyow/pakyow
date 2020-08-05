RSpec.describe "loading the common backend into applications" do
  before do
    Pakyow.config.root = File.expand_path("../common/support/project", __FILE__)
  end

  include_context "app"

  let(:env_def) {
    Proc.new {
      class TestController
      end

      class TestResource
      end

      app :test_1 do
        definable :controller, TestController
        definable :resource, TestResource

        aspect :controllers
        aspect :resources
      end

      app :test_2 do
        definable :controller, TestController
        definable :resource, TestResource

        aspect :controllers
      end
    }
  }

  it "loads the defined backend aspects into each application" do
    expect(Pakyow.app(:test_1).controllers(:root)).to be(Test1::Controllers::Root)
    expect(Pakyow.app(:test_1).controllers(:other)).to be(Test1::Controllers::Other)
    expect(Pakyow.app(:test_1).resources(:posts)).to be(Test1::Resources::Posts)
    expect(Pakyow.app(:test_2).controllers(:other)).to be(Test2::Controllers::Other)
  end

  it "does not load undefined aspects into an application" do
    expect(Pakyow.app(:test_2).resources(:posts)).to be(nil)
  end

  context "application defines state of the same type and name" do
    it "gives precedence to application state" do
      expect(Pakyow.app(:test_1).controllers(:root).context).to eq(:application)
    end

    it "extends the common state" do
      expect(Pakyow.app(:test_1).controllers(:root).common?).to be(true)
    end
  end
end
