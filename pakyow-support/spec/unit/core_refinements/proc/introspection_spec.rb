require "pakyow/support/core_refinements/proc/introspection"

RSpec.describe Pakyow::Support::Refinements::Proc::Introspection do
  using Pakyow::Support::Refinements::Proc::Introspection

  describe "#keyword_argument?" do
    context "proc accepts no arguments" do
      let :proc do
        Proc.new do
        end
      end

      it "returns false" do
        expect(proc.keyword_argument?(:bar)).to be(false)
      end
    end

    context "proc accepts one argument" do
      let :proc do
        Proc.new do |bar|
        end
      end

      it "returns false" do
        expect(proc.keyword_argument?(:bar)).to be(false)
      end
    end

    context "proc accepts one keyword argument" do
      let :proc do
        Proc.new do |bar: nil|
        end
      end

      it "returns true when the name matches" do
        expect(proc.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(proc.keyword_argument?(:baz)).to be(false)
      end
    end

    context "proc accepts two arguments, one of them a keyword argument" do
      let :proc do
        Proc.new do |baz, bar: nil|
        end
      end

      it "returns true when the name matches" do
        expect(proc.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(proc.keyword_argument?(:baz)).to be(false)
      end
    end

    context "proc accepts multiple keyword arguments" do
      let :proc do
        Proc.new do |bar: nil, baz: nil|
        end
      end

      it "returns true when the name matches one" do
        expect(proc.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match either" do
        expect(proc.keyword_argument?(:qux)).to be(false)
      end
    end

    context "proc requires a keyword argument" do
      let :proc do
        Proc.new do |bar:|
        end
      end

      it "returns true when the name matches" do
        expect(proc.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(proc.keyword_argument?(:baz)).to be(false)
      end
    end
  end

  describe "#keyword_argument?" do
    context "proc accepts no arguments" do
      let :proc do
        Proc.new do
        end
      end

      it "returns false" do
        expect(proc.keyword_arguments?).to be(false)
      end
    end

    context "proc accepts one argument" do
      let :proc do
        Proc.new do |bar|
        end
      end

      it "returns false" do
        expect(proc.keyword_arguments?).to be(false)
      end
    end

    context "proc accepts one keyword argument" do
      let :proc do
        Proc.new do |bar: nil|
        end
      end

      it "returns true" do
        expect(proc.keyword_arguments?).to be(true)
      end
    end

    context "proc accepts two arguments, one of them a keyword argument" do
      let :proc do
        Proc.new do |baz, bar: nil|
        end
      end

      it "returns true" do
        expect(proc.keyword_arguments?).to be(true)
      end
    end

    context "proc accepts multiple keyword arguments" do
      let :proc do
        Proc.new do |bar: nil, baz: nil|
        end
      end

      it "returns true" do
        expect(proc.keyword_arguments?).to be(true)
      end
    end

    context "proc requires a keyword argument" do
      let :proc do
        Proc.new do |bar:|
        end
      end

      it "returns true" do
        expect(proc.keyword_arguments?).to be(true)
      end
    end

    context "proc accepts a keyword argument glob" do
      let :proc do
        Proc.new do |**args|
        end
      end

      it "returns true" do
        expect(proc.keyword_arguments?).to be(true)
      end
    end
  end

  describe "#argument_list" do
    context "proc accepts no arguments" do
      let :proc do
        Proc.new do
        end
      end

      it "returns false" do
        expect(proc.argument_list?).to be(false)
      end
    end

    context "proc accepts one argument" do
      let :proc do
        Proc.new do |bar|
        end
      end

      it "returns true" do
        expect(proc.argument_list?).to be(true)
      end
    end

    context "proc accepts one keyword argument" do
      let :proc do
        Proc.new do |bar: nil|
        end
      end

      it "returns false" do
        expect(proc.argument_list?).to be(false)
      end
    end

    context "proc accepts two arguments, one of them a keyword argument" do
      let :proc do
        Proc.new do |baz, bar: nil|
        end
      end

      it "returns true" do
        expect(proc.argument_list?).to be(true)
      end
    end

    context "proc accepts an argument glob" do
      let :proc do
        Proc.new do |*args|
        end
      end

      it "returns true" do
        expect(proc.argument_list?).to be(true)
      end
    end
  end
end
