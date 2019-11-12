RSpec.describe "setting up the environment deprecator" do
  context "before setup" do
    it "exposes a default deprecator" do
      expect(Pakyow.deprecator).to be_instance_of(Pakyow::Support::Deprecator)
    end

    describe "default deprecator" do
      it "uses the log reporter" do
        expect(
          Pakyow.deprecator.instance_variable_get(:@reporter)
        ).to be_instance_of(Pakyow::Support::Deprecator::Reporters::Log)
      end

      it "reports to the environment logger" do
        expect(
          Pakyow.deprecator.instance_variable_get(:@reporter).instance_variable_get(:@logger)
        ).to be(Pakyow.logger)
      end
    end
  end

  shared_examples "string configured reporter" do
    before do
      local = self
      Pakyow.configure :test do
        config.deprecator.reporter = local.reporter
      end
    end

    include_context "app"

    it "sets up the deprecator" do
      expect(
        Pakyow.deprecator.instance_variable_get(:@reporter)
      ).to be(Pakyow::Support::Deprecator::Reporters::Null)
    end
  end

  context "configured reporter is a string" do
    it_behaves_like "string configured reporter" do
      let(:reporter) {
        "null"
      }
    end
  end

  context "configured reporter is a symbol" do
    it_behaves_like "string configured reporter" do
      let(:reporter) {
        :null
      }
    end
  end

  context "configured reporter is a class" do
    before do
      local = self
      Pakyow.configure :test do
        config.deprecator.reporter = local.reporter
      end
    end

    include_context "app"

    let(:reporter) {
      Class.new
    }

    it "sets up the deprecator" do
      expect(
        Pakyow.deprecator.instance_variable_get(:@reporter)
      ).to be(reporter)
    end

    context "deprecator responds to default" do
      let(:reporter) {
        Class.new do
          def self.default
            "default"
          end
        end
      }

      it "sets up the deprecator" do
        expect(
          Pakyow.deprecator.instance_variable_get(:@reporter)
        ).to eq("default")
      end
    end
  end

  context "configured reporter is an instance" do
    before do
      local = self
      Pakyow.configure :test do
        config.deprecator.reporter = local.reporter
      end
    end

    include_context "app"

    let(:reporter) {
      reporter_class.new
    }

    let(:reporter_class) {
      Class.new
    }

    it "sets up the deprecator" do
      expect(
        Pakyow.deprecator.instance_variable_get(:@reporter)
      ).to be_instance_of(reporter_class)
    end
  end

  context "configured reporter is nil" do
    before do
      Pakyow.configure :test do
        config.deprecator.reporter = nil
      end
    end

    include_context "app"

    it "sets up the global deprecator" do
      expect(Pakyow.deprecator).to be(Pakyow::Support::Deprecator.global)
    end
  end
end

RSpec.describe "reporting deprecations through the environment" do
  include_context "app"

  it "reports deprecations" do
    expect(Pakyow.deprecator).to receive(:deprecated).with(:foo)
    Pakyow.deprecated(:foo)
  end
end

RSpec.describe "reporting deprecations through the global deprecator" do
  include_context "app"

  it "forwards to the environment deprecator" do
    expect(Pakyow.deprecator).to receive(:deprecated).with(:foo)
    Pakyow::Support::Deprecator.global.deprecated(:foo)
  end
end
