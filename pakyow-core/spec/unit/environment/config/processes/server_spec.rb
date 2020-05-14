RSpec.describe Pakyow, "config.runnable.server" do
  describe "count" do
    subject { Pakyow.config.runnable.server.count }

    it "has a default value" do
      expect(subject).to eq(1)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default value" do
        expect(subject).to eq(5)
      end

      describe "setting from an env var" do
        before do
          ENV["WORKERS"] = "42"
          Pakyow.configure!(:production)
        end

        after do
          ENV.delete("WORKERS")
        end

        it "sets the value" do
          expect(subject).to eq("42")
        end
      end
    end
  end

  describe "scheme" do
    subject { Pakyow.config.runnable.server.scheme }

    it "has a default value" do
      expect(subject).to eq("http")
    end
  end

  describe "host" do
    subject { Pakyow.config.runnable.server.host }

    it "has a default value" do
      expect(subject).to eq("localhost")
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default value" do
        expect(subject).to eq("0.0.0.0")
      end

      describe "setting from an env var" do
        before do
          ENV["HOST"] = "127.0.0.1"
          Pakyow.configure!(:production)
        end

        after do
          ENV.delete("HOST")
        end

        it "sets the value" do
          expect(subject).to eq("127.0.0.1")
        end
      end
    end
  end

  describe "port" do
    subject { Pakyow.config.runnable.server.port }

    it "has a default value" do
      expect(subject).to eq(3000)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default value" do
        expect(subject).to eq(3000)
      end

      describe "setting from an env var" do
        before do
          ENV["PORT"] = "4242"
          Pakyow.configure!(:production)
        end

        after do
          ENV.delete("PORT")
        end

        it "sets the value" do
          expect(subject).to eq("4242")
        end
      end
    end
  end
end
