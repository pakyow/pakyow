require "fileutils"

require "pakyow/generator"

RSpec.describe Pakyow::Generator do
  let :source_path do
    File.expand_path("../support/generator", __FILE__)
  end

  let :destination_path do
    File.expand_path("../support/generated", __FILE__)
  end

  let :generator_class do
    Class.new(described_class)
  end

  let :instance do
    generator_class.new(source_path, **options)
  end

  let(:options) {
    {}
  }

  describe "#initialize" do
    it "initializes with a path" do
      expect {
        generator_class.new(source_path)
      }.to_not raise_error
    end
  end

  describe "#generate" do
    let :options do
      {
        foo: "bar"
      }
    end

    it "generates each file" do
      expect(instance.files.length).to eq(5)

      instance.files.each do |file|
        expect(file).to receive(:generate).with(Pathname.new(destination_path), context: instance_of(generator_class))
      end

      instance.generate(destination_path, options)
    end

    context "hooks are defined for :generate" do
      before do
        $generate_hook_calls = []

        generator_class.before "generate" do
          $generate_hook_calls << :before
        end

        generator_class.after "generate" do
          $generate_hook_calls << :after
        end

        allow_any_instance_of(Pakyow::Generator::Source).to receive(:generate)
      end

      it "invokes the hooks" do
        instance.generate(destination_path, options)
        expect($generate_hook_calls[0]).to be(:before)
        expect($generate_hook_calls[1]).to be(:after)
      end
    end

    describe "actions" do
      before do
        local = self

        generator_class.action do
          local.calls << :action
        end

        allow_any_instance_of(Pakyow::Generator::Source).to receive(:generate)
      end

      let(:calls) {
        []
      }

      it "calls actions" do
        instance.generate(destination_path, options)

        expect(calls).to eq([:action])
      end
    end
  end

  describe "#run" do
    let :runner_double do
      instance_double(Pakyow::Support::CLI::Runner)
    end

    before do
      generator_class.action do
        run "ls", message: "foo"
      end

      allow_any_instance_of(Pakyow::Generator::Source).to receive(:generate)
    end

    it "runs the command in context of the destination" do
      expect(Pakyow::Support::CLI::Runner).to receive(:new).with(message: "foo").and_return(
        runner_double
      )

      expect(runner_double).to receive(:run).with("cd #{destination_path} && ls")

      instance.generate(destination_path)
    end

    context "run is called out of context of perform" do
      it "runs the command in context of the current directory" do
        expect(Pakyow::Support::CLI::Runner).to receive(:new).with(message: "foo").and_return(
          runner_double
        )

        expect(runner_double).to receive(:run).with("cd . && ls")

        instance.run("ls", message: "foo")
      end
    end
  end

  describe "generated files" do
    let(:source_path) {
      File.expand_path("../support/generator/test.txt", __FILE__)
    }

    let(:generated_file_path) {
      "test.txt"
    }

    before do
      cleanup

      instance.generate(destination_path)
    end

    after do
      cleanup
    end

    def cleanup
      if File.exist?(destination_path)
        FileUtils.rm_r(destination_path)
      end
    end

    it "generates the file at the destination" do
      expect(File.exist?(File.join(destination_path, generated_file_path))).to be(true)
    end

    describe "the generated file" do
      it "contains the correct content" do
        expect(File.read(File.join(destination_path, generated_file_path))).to eq("this is a plain file test\n")
      end
    end

    context "file is an erb template" do
      let(:source_path) {
        File.expand_path("../support/generator/test.txt.erb", __FILE__)
      }

      let(:generated_file_path) {
        "test.txt"
      }

      it "renames the generated file" do
        expect(File.exist?(File.join(destination_path, generated_file_path))).to be(true)
      end

      it "evaluates the template" do
        expect(File.read(File.join(destination_path, generated_file_path)).strip).to eq("2")
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
      let(:source_path) {
        File.expand_path("../support/generator/%dot%gitignore", __FILE__)
      }

      let(:generated_file_path) {
        ".gitignore"
      }

      it "renames the generated file" do
        expect(File.exist?(File.join(destination_path, generated_file_path))).to be(true)
      end

      describe "the generated file" do
        it "contains the correct content" do
          expect(File.read(File.join(destination_path, generated_file_path)).strip).to eq("dotfile_test")
        end
      end
    end

    context "file is a keep file" do
      let(:source_path) {
        File.expand_path("../support/generator/test-keep", __FILE__)
      }

      it "generates the enclosing directory" do
        expect(File.directory?(File.join(destination_path, "folder"))).to be(true)
      end

      it "does not generate the keep file" do
        expect(File.exist?(File.join(destination_path, "folder/keep"))).to be(false)
      end
    end

    context "with a subclass" do
      let(:source_path) {
        File.expand_path("../support/generator/test-methods.txt.erb", __FILE__)
      }

      let(:generated_file_path) {
        "test-methods.txt"
      }

      let :generator_class do
        Class.new(described_class) do
          def foo
            "bar"
          end
        end
      end

      it "exposes content through methods" do
        expect(File.read(File.join(destination_path, generated_file_path)).strip).to eq("bar")
      end
    end
  end
end
