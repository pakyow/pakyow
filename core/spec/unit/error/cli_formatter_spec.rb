RSpec.describe Pakyow::Error::CLIFormatter do
  let :formatter do
    described_class.new(wrapped_error)
  end

  let :wrapped_error do
    begin
      raise error
    rescue => e
      wrapped = Pakyow::Error.build(e)
    end

    wrapped
  end

  let :error do
    RuntimeError.new("testing")
  end

  describe "#header" do
    it "returns a formatted string" do
      expect(formatter.header).to eq(" ERROR                                                    cli_formatter_spec.rb ")
    end
  end

  describe "#message" do
    it "returns a formatted string" do
      expect(formatter.message).to eq(
        <<~MESSAGE.rstrip
          \e[37;41;1m ERROR                                                    cli_formatter_spec.rb \e[0m

            \e[31m›\e[0m\e[90m testing\e[0m
        MESSAGE
      )
    end

    context "error has a contextual message" do
      let :error do
        Class.new(Pakyow::Error) {
          def name
            "error"
          end

          def message
            "testing"
          end

          def contextual_message
            "foo\n\nbar"
          end
        }.new
      end

      it "returns a formatted string with the contextual message" do
        expect(formatter.message).to eq("\e[37;41;1m ERROR                                                    cli_formatter_spec.rb \e[0m\n\n  \e[31m›\e[0m\e[90m testing\e[0m\n\n\e[90m  foo\n  \n  bar\e[0m")
      end
    end

    context "error message has multiple lines" do
      let :error do
        RuntimeError.new("foo\nbar")
      end

      it "returns a correctly formatted string" do
        expect(formatter.message).to eq(
          <<~MESSAGE.rstrip
            \e[37;41;1m ERROR                                                    cli_formatter_spec.rb \e[0m

              \e[31m›\e[0m\e[90m foo\e[0m
            \e[90m\nbar\e[0m
          MESSAGE
        )
      end
    end

    context "error message is empty" do
      let :error do
        RuntimeError.new("")
      end

      it "returns a correctly formatted string" do
        expect(formatter.message).to eq(
          <<~MESSAGE.rstrip
            \e[37;41;1m ERROR                                                    cli_formatter_spec.rb \e[0m
          MESSAGE
        )
      end
    end

    context "error message has whitespace at the end" do
      let :error do
        RuntimeError.new("testing\n\n\n")
      end

      it "returns a stripped formatted string" do
        expect(formatter.message).to eq(
          <<~MESSAGE.rstrip
            \e[37;41;1m ERROR                                                    cli_formatter_spec.rb \e[0m

              \e[31m›\e[0m\e[90m testing\e[0m
          MESSAGE
        )
      end
    end
  end

  describe "#details" do
    it "returns a formatted string" do
      expect(formatter.details).to eq("\e[90m  \e[3;34mRuntimeError\e[0m occurred on line \e[3;34m8\e[0m of \e[3;34mspec/unit/error/cli_formatter_spec.rb\e[0m\e[90m:\n  \n      8|›       raise error\e[0m")
    end
  end

  describe "#backtrace" do
    it "returns a formatted string" do
      expect(formatter.backtrace).to eq(
        <<~MESSAGE.rstrip
          spec/unit/error/cli_formatter_spec.rb:8:in `block (2 levels) in <top (required)>'
          spec/unit/error/cli_formatter_spec.rb:3:in `block (2 levels) in <top (required)>'
          spec/unit/error/cli_formatter_spec.rb:115:in `block (3 levels) in <top (required)>'
        MESSAGE
      )
    end
  end
end
