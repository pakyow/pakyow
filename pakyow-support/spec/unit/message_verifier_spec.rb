require "pakyow/support/message_verifier"

RSpec.describe Pakyow::Support::MessageVerifier do
  let :instance do
    described_class.new
  end

  describe "#initialize" do
    it "generates a key" do
      expect(SecureRandom).to receive(:hex).with(24).and_return("key")
      expect(described_class.new.key).to eq("key")
    end

    context "passed a key" do
      it "uses the passed key" do
        expect(described_class.new("key").key).to eq("key")
      end
    end
  end

  describe "#sign" do
    let :message do
      "message"
    end

    let :digest do
      "digest"
    end

    it "signs the message" do
      expect(described_class).to receive(:digest).with(message, key: instance.key).and_return(digest)
      expect(instance.sign(message)).to eq("#{message}:#{digest}")
    end
  end

  describe "#verify" do
    let :message do
      "message"
    end

    let :signed do
      instance.sign(message)
    end

    context "signed message has a valid digest" do
      it "returns the message" do
        expect(instance.verify(signed)).to eq(message)
      end
    end

    context "signed message has an invalid digest" do
      let :invalid do
        signed.split(":", 2).tap do |invalid|
          invalid[1] = "KGE5uuSSRq11U8icr7aJOCBUPHM1W7IoyGHSIzDRGAc="
        end.join(":")
      end

      it "raises TamperedMessage" do
        expect {
          instance.verify(invalid)
        }.to raise_error(Pakyow::Support::MessageVerifier::TamperedMessage)
      end
    end

    context "signed message has changed" do
      let :invalid do
        signed.split(":", 2).tap do |invalid|
          invalid[0] = "hacked"
        end.join(":")
      end

      it "raises TamperedMessage" do
        expect {
          instance.verify(invalid)
        }.to raise_error(Pakyow::Support::MessageVerifier::TamperedMessage)
      end
    end

    context "signed message has no digest" do
      let :invalid do
        message
      end

      it "raises TamperedMessage" do
        expect {
          instance.verify(invalid)
        }.to raise_error(Pakyow::Support::MessageVerifier::TamperedMessage)
      end
    end
  end

  describe "::key" do
    it "returns a random 48 character key" do
      expect(described_class.key.length).to eq(48)
      expect(described_class.key).to_not eq(described_class.key)
    end
  end

  describe "::digest" do
    let :digest_double do
      instance_double(OpenSSL::Digest)
    end

    let :message do
      "message"
    end

    let :key do
      "key"
    end

    let :digest do
      "digest"
    end

    let :encoded do
      double
    end

    let :final do
      "final"
    end

    it "returns a base64 encoded hmac digest stripped of whitespace" do
      expect(OpenSSL::Digest).to receive(:new).with("sha256").and_return(digest_double)
      expect(OpenSSL::HMAC).to receive(:digest).with(digest_double, message, key).and_return(digest)
      expect(Base64).to receive(:encode64).and_return(encoded)
      expect(encoded).to receive(:strip).and_return(final)
      expect(described_class.digest(message, key: key)).to be(final)
    end
  end

  describe "::valid?" do
    let :message do
      "message"
    end

    let :key do
      "key"
    end

    context "passed a valid digest" do
      let :digest do
        described_class.digest(message, key: key)
      end

      it "returns true" do
        expect(described_class.valid?(digest, message: message, key: key)).to be(true)
      end
    end

    context "passed an invalid digest" do
      let :digest do
        "invalid"
      end

      it "returns false" do
        expect(described_class.valid?(digest, message: message, key: key)).to be(false)
      end
    end
  end
end
