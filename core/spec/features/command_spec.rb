RSpec.describe "command" do
  include_context "app"
  include_context "cli"

  before do
    define
  end

  def define
    Pakyow.command(*name, &definition)
  end

  let(:name) {
    [:foo]
  }

  let(:definition) {
    Proc.new {}
  }

  it "can be defined" do
    expect(Pakyow.commands(:foo).name).to eq("Pakyow::Commands::Foo")
  end

  it "can be called" do
    expect {
      Pakyow.commands(:foo).call
    }.not_to raise_error
  end

  describe "return value" do
    it "returns self" do
      expect(Pakyow.commands(:foo).call).to be(Pakyow.commands(:foo))
    end
  end

  describe "defining with a description" do
    def define
      Pakyow.command(*name) do
        describe "hello"
      end
    end

    it "can be defined" do
      expect(Pakyow.commands(:foo).description).to eq("hello")
    end
  end

  describe "defining with actions" do
    let(:definition) {
      local = self
      Proc.new {
        action :foo do
          local.calls << :foo
        end

        action :bar do
          local.calls << :bar
        end

        action :baz do
          local.calls << :baz
        end
      }
    }

    let(:calls) {
      []
    }

    it "can be called" do
      Pakyow.commands(:foo).call

      expect(calls).to eq(%i(foo bar baz))
    end
  end

  describe "defining with arguments" do
    let(:definition) {
      local = self
      Proc.new {
        argument :foo

        action do
          local.calls << { foo: foo }
        end
      }
    }

    let(:calls) {
      []
    }

    it "can be called with the argument" do
      Pakyow.commands(:foo).call(foo: "foo value")

      expect(calls).to eq([{ foo: "foo value" }])
    end

    it "can be called without the argument" do
      Pakyow.commands(:foo).call

      expect(calls).to eq([{ foo: nil }])
    end

    context "required arguments are missing" do
      let(:definition) {
        Proc.new {
          argument :foo, required: true

          action do
          end
        }
      }

      it "fails when called" do
        expect {
          Pakyow.commands(:foo).call
        }.to raise_error(Pakyow::InvalidData)
      end
    end
  end

  describe "defining with options" do
    let(:definition) {
      local = self
      Proc.new {
        option :foo

        action do
          local.calls << { foo: foo }
        end
      }
    }

    let(:calls) {
      []
    }

    it "can be called with the option" do
      Pakyow.commands(:foo).call(foo: "foo value")

      expect(calls).to eq([{ foo: "foo value" }])
    end

    it "can be called without the option" do
      Pakyow.commands(:foo).call

      expect(calls).to eq([{ foo: nil }])
    end

    context "required options are missing" do
      let(:definition) {
        Proc.new {
          option :foo, required: true

          action do
          end
        }
      }

      it "fails when called" do
        expect {
          Pakyow.commands(:foo).call
        }.to raise_error(Pakyow::InvalidData)
      end
    end

    context "option has a default value" do
      let(:definition) {
        local = self
        Proc.new {
          option :foo, default: "foo"

          action do
            local.calls << { foo: foo }
          end
        }
      }

      it "is called with the default value" do
        Pakyow.commands(:foo).call

        expect(calls).to eq([{ foo: "foo" }])
      end
    end
  end

  describe "defining with flags" do
    let(:definition) {
      local = self
      Proc.new {
        flag :foo

        action do
          local.calls << { foo: foo }
        end
      }
    }

    let(:calls) {
      []
    }

    it "can be called with the flag" do
      Pakyow.commands(:foo).call(foo: true)

      expect(calls).to eq([{ foo: true }])
    end

    it "can be called without the flag, defaulting the flag to false" do
      Pakyow.commands(:foo).call

      expect(calls).to eq([{ foo: false }])
    end
  end

  describe "defining with a namespace" do
    let(:definition) {
      local = self
      Proc.new {
        action do
          local.calls << {}
        end
      }
    }

    let(:name) {
      [:foo, :bar]
    }

    let(:calls) {
      []
    }

    it "can be called" do
      Pakyow.commands(:foo, :bar).call

      expect(calls).to eq([{}])
    end
  end

  describe "defining with a dependency" do
    def define
      local = self

      Pakyow.command :primary, dependent: [:dependent] do
        action do
          local.calls << :primary
        end
      end

      Pakyow.command :dependent do
        action do
          local.calls << :dependent
        end
      end
    end

    let(:calls) {
      []
    }

    it "calls the commands in order" do
      Pakyow.commands(:primary).call

      expect(calls).to eq([:dependent, :primary])
    end

    context "dependency is namespaced" do
      def define
        local = self

        Pakyow.command :primary, dependent: [:"namespaced:dependent"] do
          action do
            local.calls << :primary
          end
        end

        Pakyow.command :namespaced, :dependent do
          action do
            local.calls << :dependent
          end
        end
      end

      it "calls the commands in order" do
        Pakyow.commands(:primary).call

        expect(calls).to eq([:dependent, :primary])
      end
    end
  end

  describe "calling through the dynamic lookup" do
    let(:definition) {
      local = self
      Proc.new {
        argument :foo

        action :foo do
          local.calls << { foo: foo }
        end
      }
    }

    let(:calls) {
      []
    }

    it "calls the command" do
      Pakyow.commands.foo(foo: "foov")

      expect(calls).to eq([{ foo: "foov" }])
    end
  end

  describe "deprecating a command" do
    let(:definition) {
      Proc.new {
        deprecate
      }
    }

    it "reports a deprecated when called" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(Pakyow::Commands::Foo, solution: "do not use")

      Pakyow.commands(:foo).call
    end
  end

  describe "deprecating a flag" do
    let(:definition) {
      Proc.new {
        flag :foo
        deprecate :foo
      }
    }

    context "flag is passed" do
      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "flag `foo'", solution: "do not use")

        Pakyow.commands(:foo).call(foo: "foo")
      end
    end

    context "flag is accessed" do
      let(:definition) {
        Proc.new {
          flag :foo
          deprecate :foo

          action do
            foo
          end
        }
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "flag `foo'", solution: "do not use")

        Pakyow.commands(:foo).call
      end
    end
  end

  describe "deprecating an argument" do
    let(:definition) {
      Proc.new {
        argument :foo
        deprecate :foo
      }
    }

    context "argument is passed" do
      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "argument `foo'", solution: "do not use")

        Pakyow.commands(:foo).call(foo: "foo")
      end
    end

    context "argument is accessed" do
      let(:definition) {
        Proc.new {
          argument :foo
          deprecate :foo

          action do
            foo
          end
        }
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "argument `foo'", solution: "do not use")

        Pakyow.commands(:foo).call
      end
    end
  end

  describe "deprecating an option" do
    let(:definition) {
      Proc.new {
        option :foo
        deprecate :foo
      }
    }

    context "option is passed" do
      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "option `foo'", solution: "do not use")

        Pakyow.commands(:foo).call(foo: "foo")
      end
    end

    context "option is accessed" do
      let(:definition) {
        Proc.new {
          option :foo
          deprecate :foo

          action do
            foo
          end
        }
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(instance_of(Pakyow.commands(:foo)), "option `foo'", solution: "do not use")

        Pakyow.commands(:foo).call
      end
    end
  end

  describe "calling with the current environment" do
    let(:definition) {
      local = self
      Proc.new {
        action do
          local.env = @env
        end
      }
    }

    attr_accessor :env

    it "passes the environment" do
      Pakyow.commands(:foo).call(env: :foo)

      expect(env).to eq(:foo)
    end
  end
end
