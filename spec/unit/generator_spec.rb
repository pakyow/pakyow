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
      expect(instance.files.length).to eq(5)

      instance.files.each do |file|
        expect(file).to receive(:generate).with(destination_path, options)
      end

      instance.generate(destination_path, options)
    end

    context "hooks are defined for :generate" do
      before do
        $generate_hook_calls = []

        described_class.before :generate do
          $generate_hook_calls << :before
        end

        described_class.after :generate do
          $generate_hook_calls << :after
        end

        allow_any_instance_of(Pakyow::Generator::File).to receive(:generate)
      end

      it "invokes the hooks" do
        instance.generate(destination_path, options)
        expect($generate_hook_calls[0]).to be(:before)
        expect($generate_hook_calls[1]).to be(:after)
      end
    end
  end

  describe "#run" do
    let :instance do
      described_class.new(source_path)
    end

    let :runner_double do
      instance_double(Pakyow::Support::CLI::Runner)
    end

    it "runs the command in context of the destination" do
      instance.instance_variable_set(:@destination_path, "dest")

      expect(Pakyow::Support::CLI::Runner).to receive(:new).with(message: "foo").and_return(
        runner_double
      )

      expect(runner_double).to receive(:run).with("cd dest && ls")

      instance.run("ls", message: "foo")
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
      cleanup
      instance.generate(destination_path, options)
    end

    after do
      cleanup
    end

    let :options do
      {}
    end

    def cleanup
      if File.exist?(destination_path)
        FileUtils.rm_r(destination_path)
      end
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

    context "file is a keep file" do
      let :file_path do
        "test-keep/keep"
      end

      it "generates the enclosing directory" do
        expect(File.directory?(File.join(destination_path, "test-keep"))).to be(true)
      end

      it "does not generate the keep file" do
        expect(File.exist?(File.join(destination_path, "test-keep/keep"))).to be(false)
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
