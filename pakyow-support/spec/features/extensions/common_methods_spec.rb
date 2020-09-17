require "pakyow/support/extension"

RSpec.describe "defining common methods in an extension" do
  let(:extension) {
    Module.new {
      extend Pakyow::Support::Extension

      common_methods do
        def foo
          :foo
        end
      end
    }
  }

  let!(:klass) {
    Class.new.tap do |klass|
      klass.include extension
    end
  }

  it "extends the method" do
    expect(klass.foo).to eq(:foo)
  end

  it "includes the method" do
    expect(klass.new.foo).to eq(:foo)
  end
end
