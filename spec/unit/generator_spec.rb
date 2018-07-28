require "fileutils"

require "pakyow/generator"

RSpec.describe Pakyow::Generator do
  let :source_path do
    File.expand_path("../support/generator", __FILE__)
  end

  describe "#initialize" do
    it "initializes with a path" do
      expect {
        described_class.new(source_path)
      }.to_not raise_error
    end
  end

  describe "#generate" do
    let :destination_path do
      File.expand_path("../support/generated", __FILE__)
    end

    let :options do
      {
        foo: "bar"
      }
    end

    let :instance do
      described_class.new(source_path)
    end

    it "generates each file" do
      expect(instance.files.length).to eq(4)

      instance.files.each do |file|
        expect(file).to receive(:generate).with(destination_path, options)
      end

      instance.generate(destination_path, options)
    end
  end
end

RSpec.describe Pakyow::Generator::File do
  let :source_path do
    File.expand_path("../support/generator", __FILE__)
  end

  let :file_path do
    "test.txt"
  end

  let :destination_path do
    File.expand_path("../support/generated", __FILE__)
  end

  let :instance do
    generator_class.new(File.join(source_path, file_path), source_path)
  end

  let :generator_class do
    described_class
  end

  describe "#initialize" do
    it "initializes with a path and source path" do
      expect {
        described_class.new(File.join(source_path, file_path), source_path)
      }.to_not raise_error
    end
  end

  describe "#generate" do
    before do
      expect(File.exist?(destination_path)).to be(false)
      instance.generate(destination_path, options)
    end

    after do
      if File.exist?(destination_path)
        FileUtils.rm_r(destination_path)
      end
    end

    let :options do
      {}
    end

    it "generates the file at the destination" do
      expect(File.exist?(File.join(destination_path, file_path))).to be(true)
    end

    describe "the generated file" do
      it "contains the correct content" do
        expect(File.read(File.join(destination_path, file_path))).to eq("this is a plain file test\n")
      end
    end

    context "file is an erb template" do
      let :file_path do
        "test.txt.erb"
      end

      it "renames the generated file" do
        expect(File.exist?(File.join(destination_path, "test.txt"))).to be(true)
      end

      it "evaluates the template" do
        expect(File.read(File.join(destination_path, "test.txt")).strip).to eq("2")
      end

      context "options are passed" do
        let :options do
          {
            use_option: true,
            value: "foo"
          }
        end

        it "exposes the options as available content" do
          expect(File.read(File.join(destination_path, "test.txt")).strip).to eq("2\n\nfoo")
        end
      end
    end

    context "file is a dotfile" do
      let :file_path do
        "%dot%gitignore"
      end

      it "renames the generated file" do
        expect(File.exist?(File.join(destination_path, ".gitignore"))).to be(true)
      end

      describe "the generated file" do
        it "contains the correct content" do
          expect(File.read(File.join(destination_path, ".gitignore")).strip).to eq("dotfile_test")
        end
      end
    end

    context "with a subclass" do
      let :file_path do
        "test-methods.txt.erb"
      end

      let :generator_class do
        Class.new(described_class) do
          def foo
            "bar"
          end
        end
      end

      it "exposes content through methods" do
        expect(File.read(File.join(destination_path, "test-methods.txt")).strip).to eq("bar")
      end
    end
  end
end
