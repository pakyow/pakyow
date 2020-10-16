RSpec.describe Pakyow::Loader do
  let(:instance) {
    described_class.new(path)
  }

  let(:path) {
    "foo.rb"
  }

  after do
    described_class.reset
  end

  it "initializes with a path" do
    expect(instance.path).to be(path)
  end

  describe "::load_path" do
    before do
      allow(Dir).to receive(:glob).and_return([])
      allow(Dir).to receive(:glob).with("foo/*.rb").and_return(files)
      allow(Dir).to receive(:glob).with("foo/*").and_return(directories)

      allow(File).to receive(:directory?).and_return(false)
      allow(File).to receive(:directory?).with("foo/bar").and_return(true)

      allow(described_class).to receive(:new).and_return(loader)
    end

    let(:path) {
      "foo"
    }

    let(:files) {
      ["foo/2.rb", "foo/1.rb"]
    }

    let(:directories) {
      ["foo/bar"]
    }

    let(:target) {
      Class.new
    }

    let(:loader) {
      instance_double(described_class, call: nil)
    }

    it "loads each matching file" do
      expect(described_class).to receive(:new).with("foo/1.rb").ordered.and_return(loader)
      expect(described_class).to receive(:new).with("foo/2.rb").ordered.and_return(loader)

      described_class.load_path(path, target: target)
    end

    it "loads immediate sub directories" do
      expect(described_class).to receive(:load_path).with("foo", target: target).and_call_original
      expect(described_class).to receive(:load_path).with("foo/bar", target: target, pattern: "*.rb", reload: false)

      ignore_warnings do
        described_class.load_path(path, target: target)
      end
    end

    describe "passing a pattern" do
      before do
        allow(Dir).to receive(:glob).with("foo/*.foo").and_return(files)
      end

      let(:files) {
        ["foo/1.foo", "foo/2.foo"]
      }

      it "loads each matching file" do
        expect(described_class).to receive(:new).with("foo/1.foo").ordered.and_return(loader)
        expect(described_class).to receive(:new).with("foo/2.foo").ordered.and_return(loader)

        described_class.load_path(path, target: target, pattern: "*.foo")
      end

      it "loads immediate sub directories" do
        expect(described_class).to receive(:load_path).with("foo", target: target, pattern: "*.foo").and_call_original
        expect(described_class).to receive(:load_path).with("foo/bar", target: target, pattern: "*.foo", reload: false)

        described_class.load_path(path, target: target, pattern: "*.foo")
      end
    end

    describe "loading the same path twice" do
      before do
        described_class.load_path(path, target: target)

        files.unshift("foo/3.rb")
      end

      it "loads files that have not been loaded" do
        expect(described_class).to receive(:new).with("foo/3.rb").and_return(loader)

        described_class.load_path(path, target: target)
      end

      it "does not load files that have been loaded" do
        expect(described_class).not_to receive(:new).with("foo/1.rb").ordered
        expect(described_class).not_to receive(:new).with("foo/2.rb").ordered

        described_class.load_path(path, target: target)
      end

      describe "resetting" do
        before do
          described_class.reset
        end

        it "loads all files" do
          expect(described_class).to receive(:new).ordered.with("foo/1.rb").and_return(loader)
          expect(described_class).to receive(:new).ordered.with("foo/2.rb").and_return(loader)
          expect(described_class).to receive(:new).ordered.with("foo/3.rb").and_return(loader)

          described_class.load_path(path, target: target)
        end
      end

      describe "reloading" do
        it "loads all files" do
          expect(described_class).to receive(:new).with("foo/1.rb").ordered.and_return(loader)
          expect(described_class).to receive(:new).with("foo/2.rb").ordered.and_return(loader)
          expect(described_class).to receive(:new).with("foo/3.rb").ordered.and_return(loader)

          described_class.load_path(path, target: target, reload: true)
        end
      end
    end
  end
end
