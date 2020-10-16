require "pakyow/support/extension"

RSpec.describe "defining common prepend methods in an extension" do
  let(:extension) {
    Module.new {
      extend Pakyow::Support::Extension

      common_prepend_methods do
        def foo
          super.reverse
        end
      end
    }
  }

  let!(:klass) {
    Class.new {
      def foo
        "foo"
      end

      def self.foo
        "foo"
      end
    }.tap do |klass|
      klass.include extension
    end
  }

  it "prepends the class method" do
    expect(klass.foo).to eq("oof")
  end

  it "prepends the instance method" do
    expect(klass.new.foo).to eq("oof")
  end
end
