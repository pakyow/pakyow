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

  describe "#call" do
    before do
      allow(File).to receive(:read).and_return(code)
    end

    let(:code) {
      <<~CODE
        controller :foo do
          default do; end
        end
      CODE
    }

    context "target is a class" do
      before do
        stub_const "MyApp", target
      end

      let(:target) {
        Class.new
      }

      it "evals expectedly" do
        expect(instance).to receive(:eval) do |code, binding, path, lineno|
          expect(code).to eq(
            <<~CODE
              class MyApp
                controller :foo do
                  default do; end
                end
              end
            CODE
          )

          expect(binding).to be(TOPLEVEL_BINDING)
          expect(path).to be(path)
          expect(lineno).to eq(0)
        end

        instance.call(target)
      end
    end

    context "target is a module" do
      before do
        stub_const "MyApp", target
      end

      let(:target) {
        Module.new
      }

      it "evals expectedly" do
        expect(instance).to receive(:eval) do |code, binding, path, lineno|
          expect(code).to eq(
            <<~CODE
              module MyApp
                controller :foo do
                  default do; end
                end
              end
            CODE
          )

          expect(binding).to be(TOPLEVEL_BINDING)
          expect(path).to be(path)
          expect(lineno).to eq(0)
        end

        instance.call(target)
      end
    end

    context "target is unnamed" do
      it "fails" do
        klass = Class.new

        expect {
          instance.call(klass)
        }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq("cannot load `foo.rb' on unnamed target (`#{klass}')")
        end
      end
    end

    context "target is an object" do
      it "fails" do
        object = Class.new.new

        expect {
          instance.call(object)
        }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq("expected `#{object}' to be a class or module")
        end
      end
    end

    context "code has a magic comment" do
      let(:code) {
        <<~CODE
          # frozen_string_literal: true

          controller :foo do
            default do; end
          end
        CODE
      }

      before do
        stub_const "MyApp", target
      end

      let(:target) {
        Class.new
      }

      it "evals expectedly" do
        expect(instance).to receive(:eval) do |code, binding, path, lineno|
          expect(code).to eq(
            <<~CODE
              # frozen_string_literal: true

              class MyApp
                controller :foo do
                  default do; end
                end
              end
            CODE
          )

          expect(binding).to be(TOPLEVEL_BINDING)
          expect(path).to be(path)
          expect(lineno).to eq(0)
        end

        instance.call(target)
      end
    end

    context "code has a magic comment after a blank line" do
      let(:code) {
        <<~CODE



          # frozen_string_literal: true

          controller :foo do
            default do; end
          end
        CODE
      }

      before do
        stub_const "MyApp", target
      end

      let(:target) {
        Class.new
      }

      it "evals expectedly" do
        expect(instance).to receive(:eval) do |code, binding, path, lineno|
          expect(code).to eq(
            <<~CODE



              # frozen_string_literal: true

              class MyApp
                controller :foo do
                  default do; end
                end
              end
            CODE
          )

          expect(binding).to be(TOPLEVEL_BINDING)
          expect(path).to be(path)
          expect(lineno).to eq(0)
        end

        instance.call(target)
      end
    end
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
      ["foo/one.rb", "foo/two.rb"]
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
      expect(described_class).to receive(:new).with("foo/one.rb").and_return(loader)
      expect(described_class).to receive(:new).with("foo/two.rb").and_return(loader)

      described_class.load_path(path, target: target)
    end

    it "loads immediate sub directories" do
      expect(described_class).to receive(:load_path).with("foo", target: target).and_call_original
      expect(described_class).to receive(:load_path).with("foo/bar", target: target, pattern: "*.rb", reload: false)

      described_class.load_path(path, target: target)
    end

    describe "passing a pattern" do
      before do
        allow(Dir).to receive(:glob).with("foo/*.foo").and_return(files)
      end

      let(:files) {
        ["foo/one.foo", "foo/two.foo"]
      }

      it "loads each matching file" do
        expect(described_class).to receive(:new).with("foo/one.foo").and_return(loader)
        expect(described_class).to receive(:new).with("foo/two.foo").and_return(loader)

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

        files << "foo/three.rb"
      end

      it "loads files that have not been loaded" do
        expect(described_class).to receive(:new).with("foo/three.rb").and_return(loader)

        described_class.load_path(path, target: target)
      end

      it "does not load files that have been loaded" do
        expect(described_class).not_to receive(:new).with("foo/one.rb")
        expect(described_class).not_to receive(:new).with("foo/two.rb")

        described_class.load_path(path, target: target)
      end

      describe "resetting" do
        before do
          described_class.reset
        end

        it "loads all files" do
          expect(described_class).to receive(:new).with("foo/one.rb").and_return(loader)
          expect(described_class).to receive(:new).with("foo/two.rb").and_return(loader)
          expect(described_class).to receive(:new).with("foo/three.rb").and_return(loader)

          described_class.load_path(path, target: target)
        end
      end

      describe "reloading" do
        it "loads all files" do
          expect(described_class).to receive(:new).with("foo/one.rb").and_return(loader)
          expect(described_class).to receive(:new).with("foo/two.rb").and_return(loader)
          expect(described_class).to receive(:new).with("foo/three.rb").and_return(loader)

          described_class.load_path(path, target: target, reload: true)
        end
      end
    end
  end
end
