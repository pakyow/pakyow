RSpec.describe "creating an app" do
  def create_app
    Pakyow.app :test
  end

  def create_app_with_path(path)
    Pakyow.app :test, path: path
  end

  def create_app_without(frameworks_to_exclude)
    Pakyow.app :test, without: frameworks_to_exclude
  end

  def create_app_with_block(&block)
    Pakyow.app :test, &block
  end

  it "creates the app in a namespaced class" do
    create_app
    expect(defined?(Test::Application)).to eq("constant")
  end

  it "sets the name of the app" do
    create_app
    expect(Test::Application.config.name).to eq(:test)
  end

  it "loads all registered frameworks" do
    $calls = []

    class FooFramework
      def initialize(_)
        $calls << :initialize
      end

      def boot
        $calls << :boot
      end
    end

    Pakyow.register_framework :foo, FooFramework
    create_app

    expect($calls[0]).to eq(:initialize)
    expect($calls[1]).to eq(:boot)
  end

  it "mounts the app" do
    allow(Pakyow).to receive(:mount)
    create_app

    expect(Pakyow).to have_received(:mount).with(Test::Application, at: "/")
  end

  it "returns the app" do
    expect(create_app). to eq(Test::Application)
  end

  context "when a mount path is provided" do
    before do
      allow(Pakyow).to receive(:mount)
      create_app_with_path("/foo")
    end

    it "respects the given path" do
      expect(Pakyow).to have_received(:mount).with(Test::Application, at: "/foo")
    end
  end

  context "when frameworks are excluded" do
    before do
      class FooFramework
        def initialize(_); end
        def boot; end
      end

      Pakyow.register_framework :foo, FooFramework
    end

    it "does not load the excluded framework" do
      create_app_without([:foo])
      expect(Test::Application.ancestors).not_to include(FooFramework)
    end

    context "when exclusions are not passed as an array" do
      before do
        Pakyow.register_framework :foo, FooFramework
        create_app_without(:foo)
      end

      it "still does not load the excluded framework" do
        expect(Test::Application.ancestors).not_to include(FooFramework)
      end
    end
  end

  context "when a block is given" do
    before do
      create_app_with_block do
        config.name = :foo
      end
    end

    it "evals the given block" do
      expect(Test::Application.config.name).to eq(:foo)
    end
  end
end
