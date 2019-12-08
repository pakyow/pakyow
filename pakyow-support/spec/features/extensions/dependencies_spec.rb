require "pakyow/support/extension"

RSpec.describe "defining dependencies for an extension" do
  let(:extension) {
    local = self

    Module.new {
      extend Pakyow::Support::Extension

      include_dependency local.dependency
    }
  }

  let(:dependency) {
    local = self

    Module.new {
      define_singleton_method :included do |_|
        local.included << :included
      end

      define_singleton_method :extended do |_|
        local.extended << :extended
      end
    }
  }

  let(:included) {
    []
  }

  let(:extended) {
    []
  }

  let!(:klass) {
    Class.new.tap do |klass|
      klass.include extension
    end
  }

  it "includes the dependency" do
    expect(klass.ancestors).to include(dependency)
  end

  context "dependency is already present" do
    before do
      klass.include extension
    end

    it "is not included again" do
      expect(included.count).to eq(1)
    end
  end

  context "dependency is set to extend" do
    let(:extension) {
      local = self

      Module.new {
        extend Pakyow::Support::Extension

        extend_dependency local.dependency
      }
    }

    it "extends the dependency" do
      expect(klass.singleton_class.ancestors).to include(dependency)
    end

    context "dependency is already present" do
      before do
        klass.extend extension
      end

      it "is not extended again" do
        expect(extended.count).to eq(1)
      end
    end
  end
end
