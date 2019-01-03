RSpec.describe Pakyow::Error do
  describe "::build" do
    it "wraps the original error" do
      original_error = StandardError.new("something went wrong")
      expect(described_class.build(original_error).wrapped_exception).to be(original_error)
    end

    context "context is provided" do
      it "sets the context" do
        original_error = StandardError.new("something went wrong")
        expect(described_class.build(original_error, context: self).context).to be(self)
      end
    end
  end

  describe "::new_with_message" do
    it "initializes with an empty message" do
      expect(described_class.new_with_message.message).to eq("")
    end

    context "subclass defines its own messages" do
      let :error do
        Class.new(described_class) do
          class_state :messages, default: {
            default: "default message",
            custom: "custom message"
          }
        end
      end

      it "initializes with the default message" do
        expect(error.new_with_message.message).to eq("default message")
      end

      it "initializes with a custom message" do
        expect(error.new_with_message(:custom).message).to eq("custom message")
      end
    end

    context "message contains variables" do
      let :error do
        Class.new(described_class) do
          class_state :messages, default: {
            default: "hello {name}",
          }
        end
      end

      it "builds the proper string" do
        expect(error.new_with_message(name: "bob").message).to eq("hello bob")
      end
    end
  end

  describe "#cause" do
    it "returns the wrapped error" do
      original_error = StandardError.new("something went wrong")
      expect(described_class.build(original_error).cause).to be(original_error)
    end
  end

  describe "#name" do
    class AnotherError < Pakyow::Error; end
    it "defaults to a human version of the class" do
      expect(AnotherError.new("something went wrong").name).to eq("Another error")
    end
  end

  describe "#details" do
    context "error occurred within a framework" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(false)
      end

      it "says that the error occurred within a framework" do
        begin
          fail "something went wrong"
        rescue => error
          expect(error).to receive(:backtrace_locations).and_return(
            [double(:backtrace_location, absolute_path: File.join(Gem.default_dir, "gems/pakyow-core-1.0.0"))]
          )

          wrapped = described_class.build(error)
        end

        path = Pathname.new(__FILE__).relative_path_from(
          Pathname.new(Pakyow.config.root)
        )

        expect(wrapped.details).to eq(
          <<~MESSAGE
            `RuntimeError' occurred outside of your project, within the `core' framework.
          MESSAGE
        )
      end
    end

    context "error occurred within a gem" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(false)
      end

      it "says that the error occurred within the gem" do
        begin
          fail "something went wrong"
        rescue => error
          expect(error).to receive(:backtrace_locations).and_return(
            [double(:backtrace_location, absolute_path: File.join(Gem.default_dir, "gems/puma-3.12.0"))]
          )

          wrapped = described_class.build(error)
        end

        path = Pathname.new(__FILE__).relative_path_from(
          Pathname.new(Pakyow.config.root)
        )

        expect(wrapped.details).to eq(
          <<~MESSAGE
            `RuntimeError' occurred outside of your project, within the `puma' gem.
          MESSAGE
        )
      end
    end

    context "error occurred within the project" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(true)
      end

      it "says that the error occurred within the project, and includes the source" do
        begin
          lineno = __LINE__ + 1
          fail "something went wrong"
        rescue => error
          wrapped = described_class.build(error)
        end

        path = Pathname.new(__FILE__).relative_path_from(
          Pathname.new(Pakyow.config.root)
        )

        expect(wrapped.details).to eq(
          <<~MESSAGE
            `RuntimeError' occurred on line `#{lineno}' of `#{path}':

                #{lineno}|›           fail "something went wrong"
          MESSAGE
        )
      end

      context "backtrace is missing" do
        it "says that an error occurred" do
          expect(described_class.new("something went wrong").details).to eq(
            <<~MESSAGE
              `Pakyow::Error' occurred at an unknown location.
            MESSAGE
          )
        end
      end
    end
  end

  describe "#path" do
    context "error occurred outside the project" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(false)
      end

      it "returns the absolute path to where the error occurred" do
        begin
          fail "something went wrong"
        rescue => error
          wrapped = described_class.build(error)
        end

        expect(wrapped.path).to eq(__FILE__)
      end
    end

    context "error occurred within the project" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(true)
      end

      it "returns the relative path to where the error occurred" do
        begin
          fail "something went wrong"
        rescue => error
          wrapped = described_class.build(error)
        end

        path = Pathname.new(__FILE__).relative_path_from(
          Pathname.new(Pakyow.config.root)
        )

        expect(wrapped.path).to eq(path.to_s)
      end
    end
  end

  describe "#condensed_backtrace" do
    before do
      allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(false)
    end

    let :error do
      begin
        fail "something went wrong"
      rescue => error
        expect(error).to receive(:backtrace).and_return(
          [
            File.join(Gem.default_dir, "gems/pakyow-realtime-1.0.0/foo.rb:114:in `foo`"),
            __FILE__ + ":#{__LINE__}:in `bar`",
            File.join(Gem.default_dir, "gems/puma-3.12.0/baz.rb:42:in `baz`")
          ]
        )

        described_class.build(error)
      end
    end

    it "simplifies lines from a gem" do
      expect(error.condensed_backtrace[2]).to eq("    puma | baz.rb:42:in `baz`")
    end

    it "simplifies lines from a framework" do
      expect(error.condensed_backtrace[0]).to eq("realtime | foo.rb:114:in `foo`")
    end

    it "marks lines from the project" do
      path = Pathname.new(__FILE__).relative_path_from(
        Pathname.new(Pakyow.config.root)
      )

      expect(error.condensed_backtrace[1]).to eq("         › #{path}:214:in `bar`")
    end

    context "error occurred within the project" do
      before do
        allow_any_instance_of(Pakyow::Error).to receive(:project?).and_return(true)
      end

      let :error do
        begin
          fail "something went wrong"
        rescue => error
          expect(error).to receive(:backtrace_locations).and_return(
            [
              double(:backtrace_location, absolute_path: File.join(Gem.default_dir, "gems/pakyow-realtime-1.0.0/foo.rb:114:in `foo`")),
              double(:backtrace_location, absolute_path: __FILE__ + "#{__LINE__}:in `bar`"),
              double(:backtrace_location, absolute_path: File.join(Gem.default_dir, "gems/puma-3.12.0/baz.rb:42:in `baz`"))
            ]
          )

          described_class.build(error)
        end
      end

      it "returns only the backtrace that concerns the project" do
        expect(error.condensed_backtrace.length).to be(1)
      end
    end
  end
end
