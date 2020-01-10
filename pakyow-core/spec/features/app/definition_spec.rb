RSpec.describe "defining an app" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.name = "define-test"

      action do |connection|
        connection.body = StringIO.new(config.name)
        connection.halt
      end
    end
  end

  it "defines the app" do
    res = call
    expect(res[0]).to eq(200)
    expect(res[2]).to eq("define-test")
  end

  context "when app is a subclass" do
    let :base do
      klass = Pakyow::Application.make(:base)

      klass.define do
        config.name = "define-test"

        action do |connection|
          connection.body = StringIO.new(config.name)
          connection.halt
        end
      end

      klass
    end

    let :app do
      base.make(:test).tap do |app|
        app.define(&app_def)
      end
    end

    it "inherits parent state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("define-test")
    end

    context "and the subclassed app defines new state" do
      let :app_def do
        Proc.new do
          config.name = "child-test"
        end
      end

      it "uses the child's defined state" do
        res = call
        expect(res[0]).to eq(200)
        expect(res[2]).to eq("child-test")
      end

      it "does not modify the parent state" do
        expect(base.config.name).to eq("define-test")
      end
    end
  end

  context "when app is extended at runtime" do
    let :app_init do
      Proc.new do
        config.name = "runtime-test"
      end
    end

    it "is extended with the new state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("runtime-test")
    end

    it "does not modify the class-level state" do
      expect(app.config.name).to eq("define-test")
    end
  end

  context "app block defines a method" do
    let :app_def do
      Proc.new do; end
    end

    let :app_init do
      Proc.new do
        def call(connection)
          connection.body = StringIO.new("called")
          connection.halt
        end
      end
    end

    it "defines the method" do
      expect(call("/")[2]).to eq("called")
    end
  end
end
