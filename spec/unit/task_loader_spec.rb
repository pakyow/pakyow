require "pakyow/task"

RSpec.describe Pakyow::Task::Loader do
  let :path do
    "task.rake"
  end

  let :instance do
    described_class.new(path)
  end

  before do
    allow(File).to receive(:read).with(path).and_return("task file")
    allow_any_instance_of(described_class).to receive(:eval)
  end

  describe "#initialize" do
    it "evals the contents of the given file" do
      expect_any_instance_of(described_class).to receive(:eval) { |instance, code, binding, path|
        expect(code).to eq("task file")
        expect(binding.receiver).to be(instance)
        expect(path).to eq(path)
      }

      instance
    end

    it "initializes internal state" do
      expect(instance.__namespace).to eq([])
      expect(instance.__description).to be(nil)
      expect(instance.__arguments).to eq({})
      expect(instance.__options).to eq({})
      expect(instance.__tasks).to eq([])
    end
  end

  describe "#namespace" do
    it "builds the namespace" do
      internal_namespace = nil
      instance.namespace "foo" do
        internal_namespace = __namespace.dup
      end

      expect(internal_namespace).to eq([:foo])
    end

    it "execs the given block" do
      context = nil
      instance.namespace :foo do
        context = self
      end

      expect(context).to be(instance)
    end

    it "restores the namespace" do
      instance.namespace :foo do
      end

      expect(instance.__namespace).to eq([])
    end

    describe "nested namespaces" do
      it "builds the namespace" do
        internal_namespace = nil
        instance.namespace :foo do
          namespace :bar do
            internal_namespace = __namespace.dup
          end
        end

        expect(internal_namespace).to eq([:foo, :bar])
      end

      it "execs the given block" do
        context = nil
        instance.namespace :foo do
          namespace :bar do
            context = self
          end
        end

        expect(context).to be(instance)
      end

      it "restores the namespace" do
        internal_namespace = nil
        instance.namespace :foo do
          namespace :bar do
            context = self
          end

          internal_namespace = __namespace.dup
        end

        expect(internal_namespace).to eq([:foo])
        expect(instance.__namespace).to eq([])
      end
    end
  end

  describe "#describe" do
    it "sets the description" do
      instance.describe "foo"
      expect(instance.__description).to eq("foo")
    end
  end

  describe "#desc" do
    it "sets the description" do
      instance.desc "foo"
      expect(instance.__description).to eq("foo")
    end
  end

  describe "#argument" do
    it "sets the argument, defaulting to not required" do
      instance.argument("foo", "foo description")
      expect(instance.__arguments[:foo]).to eq({
        description: "foo description",
        required: false
      })
    end

    context "passing required true" do
      it "makes the argument required" do
        instance.argument("foo", "foo description", required: true)
        expect(instance.__arguments[:foo]).to eq({
          description: "foo description",
          required: true
        })
      end
    end
  end

  describe "#option" do
    it "sets the option, defaulting to not required" do
      instance.option("foo", "foo description")
      expect(instance.__options[:foo]).to eq({
        description: "foo description",
        required: false,
        short: :default
      })
    end

    context "passing required true" do
      it "makes the option required" do
        instance.option("foo", "foo description", required: true)
        expect(instance.__options[:foo]).to eq({
          description: "foo description",
          required: true,
          short: :default
        })
      end
    end
  end

  describe "#task" do
    it "creates a task" do
      block = Proc.new do; end

      expect(Pakyow::Task).to receive(:new).with({
        namespace: [:ns],
        description: "task that does foo",
        arguments: {
          foo: {
            description: "foo argument",
            required: false
          }
        },
        options: {
          app: {
            description: "The app to run the command on",
            global: true
          },
          env: {
            description: "What environment to use",
            global: true
          },
          bar: {
            description: "bar option",
            required: false,
            short: :default
          }
        },
        flags: {
          baz: {
            description: "baz flag",
            short: nil
          }
        },
        task_args: [:foo_task, [:app, :foo, :bar, :baz]],
        global: false,
      }, &block)

      instance.describe "task that does foo"
      instance.argument :foo, "foo argument"
      instance.option :bar, "bar option"
      instance.flag :baz, "baz flag"
      instance.namespace :ns do
        task :foo_task, [:app, :foo, :bar, :baz], &block
      end

      expect(instance.__tasks.count).to be(1)
    end

    it "resets the description" do
      instance.describe "task that does foo"
      instance.task :foo_task do; end
      expect(instance.__description).to be(nil)
    end
  end
end
