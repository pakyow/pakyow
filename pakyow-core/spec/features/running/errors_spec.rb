RSpec.describe "handling errors when running" do
  include_context "runnable"

  before do
    allow(Pakyow.logger).to receive(:houston)
  end

  let(:runnable_mode) {
    :single_service
  }

  context "an application fails to run" do
    before do
      Pakyow.app :test_1 do
        on "setup" do
          fail
        end
      end

      Pakyow.app :test_2 do
      end
    end

    it "rescues the failed application" do
      expect(Pakyow.app(:test_1)).to receive(:rescue!).and_call_original

      Pakyow.run
    end

    it "continues running other applications" do
      expect(Pakyow.app(:test_2)).not_to receive(:rescue!)

      Pakyow.run
    end

    it "does not rescue the environment" do
      expect(Pakyow).not_to receive(:rescue!)

      Pakyow.run
    end
  end

  context "something in the environment fails" do
    before do
      Pakyow.on :boot, exec: false do
        raise error
      end
    end

    let(:error) {
      begin
        fail "something went wrong"
      rescue => error
        error
      end
    }

    it "rescues the environment" do
      expect(Pakyow).to receive(:rescue!).at_least(:once).and_call_original

      Pakyow.run

      expect(Pakyow.error).to be_instance_of(Pakyow::EnvironmentError)
      expect(Pakyow.error.cause).to be(error)
    end
  end

  context "script error is encountered" do
    before do
      allow(Pakyow).to receive(:boot).and_raise(error)
    end

    let(:error) {
      ScriptError.new
    }

    it "rescues the environment" do
      expect(Pakyow).to receive(:rescue!).at_least(:once).and_call_original

      Pakyow.run

      expect(Pakyow.error).to be_instance_of(Pakyow::EnvironmentError)
      expect(Pakyow.error.cause).to be(error)
    end
  end

  context "some other error is encountered" do
    before do
      allow(Pakyow).to receive(:boot).and_raise(error)
    end

    let(:error) {
      begin
        fail "something went wrong"
      rescue => error
        error
      end
    }

    it "rescues the environment" do
      expect(Pakyow).to receive(:rescue!).at_least(:once).and_call_original

      Pakyow.run

      expect(Pakyow.error).to be_instance_of(Pakyow::EnvironmentError)
      expect(Pakyow.error.cause).to be(error)
    end
  end

  # Not finding a way to run this case without stopping rspec, but leaving it here for later.
  #
  context "signal error is encountered" do
    before do
      allow(Pakyow).to receive(:load).and_raise(error)
    end

    let(:error) {
      SignalException.new(:HUP)
    }

    xit "does not rescue the environment" do
      expect(Pakyow).to receive(:rescue!).at_least(:once).and_call_original

      Pakyow.run
    end
  end

  describe "handling custom errors" do
    before do
      class SomeError < StandardError; end

      local = self
      Pakyow.container(:supervisor).service(:environment).handle(SomeError) do
        local.handled = true
      end

      allow(Pakyow).to receive(:boot).and_raise(SomeError)
    end

    attr_accessor :handled

    it "handles" do
      Pakyow.run

      expect(@handled).to be(true)
    end
  end
end
