RSpec.describe Pakyow::Loader do
  let(:instance) {
    described_class.new(path)
  }

  let(:path) {
    "foo.rb"
  }

  it "initializes with a path" do
    expect(instance.path).to be(path)
  end

  describe "#call" do
    before do
      allow(File).to receive(:read).and_return(
        <<~CODE
          controller :foo do
            default do; end
          end
        CODE
      )
    end

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
  end
end
