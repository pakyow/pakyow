require "pakyow/plugin"

RSpec.describe "configuring a plugin instance" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      setting :foo, :bar
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/" do
        configure do
          config.foo = :baz
        end
      end

      plug :testable, at: "/foo", as: :foo do
        configure do
          config.foo = :qux
        end
      end
    end
  end

  it "sets the configuration options for each plug" do
    expect(
      Pakyow.app(:test).plugs.testable.config.foo
    ).to eq(:baz)

    expect(
      Pakyow.app(:test).plugs.testable(:foo).config.foo
    ).to eq(:qux)
  end

  context "configuring for a specific environment" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/" do
          configure :test do
            config.foo = :test_baz
          end
        end

        plug :testable, at: "/foo", as: :foo do
          configure :test do
            config.foo = :test_qux
          end
        end
      end
    end

    it "configures each plug for the environment" do
      expect(
        Pakyow.app(:test).plugs.testable.config.foo
      ).to eq(:test_baz)

      expect(
        Pakyow.app(:test).plugs.testable(:foo).config.foo
      ).to eq(:test_qux)
    end
  end
end
