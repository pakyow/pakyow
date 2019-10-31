require "pakyow/support/system"

RSpec.describe Pakyow::Support::System do
  before do
    allow(File).to receive(:expand_path).with(".").and_return("/")
  end

  describe "#pwd" do
    it "expands ." do
      expect(subject.pwd.to_s).to eq("/")
    end

    it "returns a pathname" do
      expect(subject.pwd).to be_instance_of(Pathname)
    end

    it "memoizes" do
      expect(subject.pwd).to be(subject.pwd)
    end
  end

  describe "#gemfile" do
    it "is a path to the gemfile, relative to pwd" do
      expect(subject.gemfile.to_s).to eq("/Gemfile")
    end

    it "returns a pathname" do
      expect(subject.gemfile).to be_instance_of(Pathname)
    end

    it "memoizes" do
      expect(subject.gemfile).to be(subject.gemfile)
    end
  end

  describe "#gemfile?" do
    before do
      allow(subject).to receive(:gemfile).and_return(gemfile_double)
    end

    let(:gemfile_double) {
      instance_double(Pathname, exist?: true)
    }

    it "checks if the gemfile exists" do
      expect(subject.gemfile?).to be(true)
    end
  end

  context "included into a class" do
    subject { Class.new.tap { |c| c.include described_class }.new }

    describe "#pwd" do
      it "is private" do
        expect { subject.pwd }.to raise_error(NoMethodError)
      end

      it "behaves like ::pwd" do
        expect(subject.send(:pwd)).to eq(described_class.pwd)
      end
    end

    describe "#gemfile" do
      it "is private" do
        expect { subject.gemfile }.to raise_error(NoMethodError)
      end

      it "behaves like ::gemfile" do
        expect(subject.send(:gemfile)).to eq(described_class.gemfile)
      end
    end

    describe "#gemfile?" do
      it "is private" do
        expect { subject.gemfile? }.to raise_error(NoMethodError)
      end

      it "behaves like ::gemfile?" do
        expect(subject.send(:gemfile?)).to eq(described_class.gemfile?)
      end
    end
  end
end
