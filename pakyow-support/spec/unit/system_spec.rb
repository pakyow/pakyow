require "pakyow/support/system"

RSpec.describe Pakyow::Support::System do
  before do
    allow(File).to receive(:expand_path).with(".").and_return("/")
  end

  describe "#current_path" do
    it "expands ." do
      expect(subject.current_path.to_s).to eq("/")
    end

    it "returns a pathname" do
      expect(subject.current_path).to be_instance_of(Pathname)
    end

    it "memoizes" do
      expect(subject.current_path).to be(subject.current_path)
    end
  end

  describe "#gemfile_path" do
    it "is a path to the gemfile, relative to current_path" do
      expect(subject.gemfile_path.to_s).to eq("/Gemfile")
    end

    it "returns a pathname" do
      expect(subject.gemfile_path).to be_instance_of(Pathname)
    end

    it "memoizes" do
      expect(subject.gemfile_path).to be(subject.gemfile_path)
    end
  end

  describe "#gemfile?" do
    before do
      allow(subject).to receive(:gemfile_path).and_return(gemfile_path_double)
    end

    let(:gemfile_path_double) {
      instance_double(Pathname, exist?: true)
    }

    it "checks if the gemfile exists" do
      expect(subject.gemfile?).to be(true)
    end
  end

  context "included into a class" do
    subject { Class.new.tap { |c| c.include described_class }.new }

    describe "#current_path" do
      it "is private" do
        expect { subject.current_path }.to raise_error(NoMethodError)
      end

      it "behaves like ::current_path" do
        expect(subject.send(:current_path)).to eq(described_class.current_path)
      end
    end

    describe "#gemfile_path" do
      it "is private" do
        expect { subject.gemfile_path }.to raise_error(NoMethodError)
      end

      it "behaves like ::gemfile_path" do
        expect(subject.send(:gemfile_path)).to eq(described_class.gemfile_path)
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
