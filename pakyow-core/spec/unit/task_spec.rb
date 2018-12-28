require "pakyow/task"

RSpec.describe Pakyow::Task do
  before do
    allow_any_instance_of(described_class).to receive(:namespace)
    allow_any_instance_of(described_class).to receive(:task).and_return(
      rake_task_double
    )
  end

  let :rake_task_double do
    double(Rake::Task, arg_names: rake_arguments, name: :test_task)
  end

  let :rake_arguments do
    []
  end

  let :instance do
    described_class.new(
      arguments: arguments,
      options: options,
      task_args: [:test_task, rake_arguments],
      description: description
    ) do; end
  end

  let :arguments do
    {}
  end

  let :options do
    {}
  end

  let :description do
    ""
  end

  it "includes Rake::DSL" do
    expect(described_class.ancestors).to include(Rake::DSL)
  end

  describe "#initialize" do
    it "defines a rake task with the given name" do
      expect_any_instance_of(described_class).to receive(:task).with(:test_task)
      described_class.new(task_args: [:test_task]) do; end
    end

    describe "the defined task" do
      it "invoked in context of the instance" do
        expect_any_instance_of(described_class).to receive(:task) do |instance, task_name, &block|
          block.call
        end

        context = nil
        instance = described_class.new(task_args: [:test_task]) do
          context = self
        end

        expect(context).to be(instance)
      end
    end

    context "with a namespace" do
      it "defines a namespaced rake task" do
        expect_any_instance_of(described_class).to receive(:namespace).with("foo").and_yield
        expect_any_instance_of(described_class).to receive(:task).with(:namespaced_task)
        described_class.new(namespace: [:foo], task_args: [:namespaced_task]) do; end
      end
    end

    context "with a nested namespace" do
      it "defines a deeply namespaced rake task" do
        expect_any_instance_of(described_class).to receive(:namespace).with("foo:bar").and_yield
        expect_any_instance_of(described_class).to receive(:task).with(:deeply_namespaced_task)
        described_class.new(namespace: [:foo, :bar], task_args: [:deeply_namespaced_task]) do; end
      end
    end

    context "with a description" do
      it "initializes" do
        expect {
          described_class.new(description: "foo", task_args: [:described_task]) do; end
        }.not_to raise_error
      end
    end

    context "with arguments" do
      it "initializes" do
        expect {
          described_class.new(arguments: {}, task_args: [:task_with_arguments]) do; end
        }.not_to raise_error
      end
    end

    context "with options" do
      it "initializes" do
        expect {
          described_class.new(options: {}, task_args: [:task_with_options]) do; end
        }.not_to raise_error
      end
    end

    context "with task args" do
      it "sets the task args" do
        expect_any_instance_of(described_class).to receive(:task).with(:test_task, [:foo, :bar])
        described_class.new(task_args: [:test_task, [:foo, :bar]]) do; end
      end
    end
  end

  describe "#call" do
    it "invokes the rake task" do
      expect(rake_task_double).to receive(:invoke).with(no_args)
      instance = described_class.new(task_args: [:test_task]) do; end
      instance.call
    end

    context "with global options" do
      let :rake_arguments do
        [:foo, :bar]
      end

      let :options do
        {
          bar: {
            description: "bar arg",
            required: true,
            global: true
          }
        }
      end

      it "invokes the rake task with global options" do
        expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
        instance.call(foo: "foo_value", bar: "bar_value")
      end

      context "optional option is missing from global options" do
        it "invokes the rake task with available global options" do
          expect(rake_task_double).to receive(:invoke).with(nil, "bar_value")
          instance.call(bar: "bar_value")
        end
      end

      context "required option is missing from global options" do
        it "raises an error" do
          expect {
            instance.call(foo: "foo_value")
          }.to raise_error(Pakyow::CLI::InvalidInput).with_message("`bar' is a required option")
        end
      end

      context "unsupported option is passed as a global option" do
        it "does not raise an error" do
          expect {
            instance.call(bar: "bar_value", baz: "baz_value")
          }.to raise_error(Pakyow::CLI::InvalidInput).with_message("`baz' is not a supported option")
        end
      end
    end

    context "with argument values" do
      let :rake_arguments do
        [:foo, :bar]
      end

      let :options do
        {
          foo: {
            description: "foo arg"
          },
          bar: {
            description: "bar arg",
            required: true
          }
        }
      end

      it "invokes the rake task with options from argument values" do
        expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
        instance.call({}, ["--foo=foo_value", "--bar=bar_value"])
      end

      it "invokes the rake task with options from argument values not separated by an equals sign" do
        expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
        instance.call({}, ["--foo=foo_value", "--bar", "bar_value"])
      end

      it "invokes the rake task with options from short argument values" do
        expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
        instance.call({}, ["-f", "foo_value", "-b", "bar_value"])
      end

      context "optional option is missing from argument values" do
        it "invokes the rake task with available options" do
          expect(rake_task_double).to receive(:invoke).with(nil, "bar_value")
          instance.call({}, ["--bar=bar_value"])
        end
      end

      context "required option is missing from argument values" do
        it "raises an error" do
          expect {
            instance.call({}, ["--foo=foo_value"])
          }.to raise_error(Pakyow::CLI::InvalidInput, "`bar' is a required option")
        end
      end

      context "unsupported option is passed as an argument value" do
        it "raises an error" do
          expect {
            instance.call({}, ["--bar=bar_value", "--baz=baz_value"])
          }.to raise_error(Pakyow::CLI::InvalidInput, "`--baz=baz_value' is not a supported option")
        end
      end

      context "argument values include an argument" do
        context "task specifies the argument" do
          let :rake_arguments do
            [:foo]
          end

          let :arguments do
            {
              foo: {
                description: "foo arg"
              }
            }
          end

          let :options do
            {}
          end

          it "uses the argument" do
            expect(rake_task_double).to receive(:invoke).with("foo_value")
            instance.call({}, ["foo_value"])
          end

          context "optional argument is missing" do
            it "invokes the rake task with available options" do
              expect(rake_task_double).to receive(:invoke).with(nil)
              instance.call({}, [])
            end
          end

          context "required argument is missing" do
            let :arguments do
              {
                foo: {
                  description: "foo arg",
                  required: true
                }
              }
            end

            it "raises an error" do
              expect {
                instance.call({}, [])
              }.to raise_error(Pakyow::CLI::InvalidInput, "`foo' is a required argument")
            end
          end

          context "unspecified argument is passed" do
            it "raises an error" do
              expect {
                instance.call({}, ["foo_value", "bar_value"])
              }.to raise_error(Pakyow::CLI::InvalidInput, "`bar_value' is not a supported argument")
            end
          end
        end

        context "task specifies arguments and options" do
          let :rake_arguments do
            [:foo, :bar]
          end

          let :arguments do
            {
              foo: {
                description: "foo arg"
              }
            }
          end

          let :options do
            {
              bar: {
                description: "bar arg"
              }
            }
          end

          context "argument is specified after options" do
            it "uses the arguments and options" do
              expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
              instance.call({}, ["--bar=bar_value", "foo_value"])
            end
          end

          context "argument is specified before options" do
            it "uses the arguments and options" do
              expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value")
              instance.call({}, ["foo_value", "--bar=bar_value"])
            end
          end
        end
      end
    end

    context "with global options and argument values" do
      let :arguments do
        {
          foo: {
            description: "foo arg"
          },
          qux: {
            description: "qux arg"
          }
        }
      end

      let :options do
        {
          bar: {
            description: "bar arg"
          },
          baz: {
            description: "baz arg"
          }
        }
      end

      let :rake_arguments do
        [:foo, :bar, :baz, :qux]
      end

      it "invokes the rake task with the right options" do
        expect(rake_task_double).to receive(:invoke).with("foo_value", "bar_value", "baz_value", "qux_value")
        instance.call({ qux: "qux_value" }, ["--baz=baz_value", "--bar=bar_value", "foo_value"])
      end

      describe "task argument order" do
        let :rake_arguments do
          [:baz, :foo, :qux, :bar]
        end

        it "orders task arguments based on the task definition" do
          expect(rake_task_double).to receive(:invoke).with("baz_value", "foo_value", "qux_value", "bar_value")
          instance.call({ qux: "qux_value" }, ["--baz=baz_value", "--bar=bar_value", "foo_value"])
        end
      end
    end
  end

  describe "#help" do
    let :description do
      "Tests help text"
    end

    it "returns help for the command" do
      expect(instance.help).to eq("\e[34;1mTests help text\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow test_task\n")
    end

    context "without the description" do
      it "returns help for the command" do
        expect(instance.help(describe: false)).to eq("\n\e[1mUSAGE\e[0m\n  $ pakyow test_task\n")
      end
    end

    context "with arguments" do
      let :arguments do
        {
          qux: {
            description: "qux arg"
          },
          foo: {
            description: "foo arg",
            required: true
          }
        }
      end

      let :rake_arguments do
        [:foo, :qux]
      end

      it "returns help for the command" do
        expect(instance.help).to eq("\e[34;1mTests help text\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow test_task [FOO]\n\n\e[1mARGUMENTS\e[0m\n  FOO  \e[33mfoo arg\e[0m\e[31m (required)\e[0m\n  QUX  \e[33mqux arg\e[0m\n")
      end
    end

    context "with options" do
      let :options do
        {
          bar: {
            description: "bar arg",
            short: :default
          },
          baz: {
            description: "baz arg",
            required: true,
            short: :default
          }
        }
      end

      let :rake_arguments do
        [:bar, :baz]
      end

      it "returns help for the command" do
        expect(instance.help).to eq("\e[34;1mTests help text\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow test_task --baz=baz\n\n\e[1mOPTIONS\e[0m\n  -b, --bar=bar  \e[33mbar arg\e[0m\n      --baz=baz  \e[33mbaz arg\e[0m\e[31m (required)\e[0m\n")
      end
    end

    context "with arguments and options" do
      let :arguments do
        {
          foo: {
            description: "foo arg",
            required: true
          },
          qux: {
            description: "qux arg"
          }
        }
      end

      let :options do
        {
          bar: {
            description: "bar arg",
            short: :default
          },
          baz: {
            description: "baz arg",
            required: true,
            short: :default
          }
        }
      end

      let :rake_arguments do
        [:foo, :bar, :baz, :qux]
      end

      it "returns help for the command" do
        expect(instance.help).to eq("\e[34;1mTests help text\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow test_task [FOO] --baz=baz\n\n\e[1mARGUMENTS\e[0m\n  FOO  \e[33mfoo arg\e[0m\e[31m (required)\e[0m\n  QUX  \e[33mqux arg\e[0m\n\n\e[1mOPTIONS\e[0m\n  -b, --bar=bar  \e[33mbar arg\e[0m\n      --baz=baz  \e[33mbaz arg\e[0m\e[31m (required)\e[0m\n")
      end
    end
  end

  describe "#app?" do
    context "task wants the app" do
      let :rake_arguments do
        [:foo, :bar, :app]
      end

      it "returns true" do
        expect(instance.app?).to be(true)
      end
    end

    context "task does not want the app" do
      let :rake_arguments do
        [:foo, :bar]
      end

      it "returns false" do
        expect(instance.app?).to be(false)
      end
    end
  end
end
