RSpec.describe "handling errors during a request lifecycle" do
  include_context "app"

  let(:response) {
    call("/")
  }

  let(:allow_request_failures) {
    true
  }

  describe "from the environment" do
    let(:env_def) {
      Proc.new {
        action do
          fail "something went wrong"
        end
      }
    }

    it "responds with the expected body" do
      expect(response[0]).to eq(500)
      expect(response[2]).to eq("500 Server Error")
    end

    context "connection headers were modified but the connection was not halted" do
      let(:env_def) {
        Proc.new {
          action do |connection|
            connection.headers["foo"] = "bar"
            fail "something went wrong"
          end
        }
      }

      it "clears the headers" do
        expect(response[1]).to be_empty
      end
    end

    context "connection body was modified but the connection was not halted" do
      let(:env_def) {
        Proc.new {
          action do |connection|
            connection.body.write "foo"
            fail "something went wrong"
          end
        }
      }

      it "returns the correct status" do
        expect(response[0]).to eq(500)
      end

      it "returns the default body" do
        expect(response[2]).to eq("500 Server Error")
      end
    end

    context "500 handler is defined on the environment" do
      let(:env_def) {
        Proc.new {
          handle 500 do |connection:|
            connection.body.write "environment_handled"
            connection.halt
          end

          action do
            fail "something went wrong"
          end
        }
      }

      it "handles the error" do
        expect(response[0]).to eq(500)
        expect(response[2]).to eq("environment_handled")
      end

      context "500 handler does not halt" do
        let(:env_def) {
          Proc.new {
            handle 500 do |connection:|
              connection.body.write "environment_handled"
            end

            action do
              fail "something went wrong"
            end
          }
        }

        it "calls the default 500 handler" do
          expect(response[0]).to eq(500)
          expect(response[2]).to eq("500 Server Error")
        end
      end
    end

    context "error handler is defined on the environment" do
      let(:env_def) {
        Proc.new {
          handle ArgumentError do |connection:|
            connection.body.write "environment_handled_argument_error"
          end

          action do |connection|
            raise Kernel.const_get(connection.params[:error])
          end
        }
      }

      it "handles matching errors" do
        response = call("/", params: { error: "ArgumentError" })

        expect(response[0]).to eq(200)
        expect(response[2]).to eq("environment_handled_argument_error")
      end

      it "does not handle unmatching errors" do
        response = call("/", params: { error: "RuntimeError" })

        expect(response[0]).to eq(500)
        expect(response[2]).to eq("500 Server Error")
      end
    end
  end

  describe "from the application" do
    let(:app_def) {
      Proc.new {
        action do
          fail "something went wrong"
        end
      }
    }

    it "responds with the expected body" do
      expect(response[0]).to eq(500)
      expect(response[2]).to eq("500 Server Error")
    end

    context "500 handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle 500 do |connection:|
            connection.body.write "application_handled"
            connection.halt
          end

          action do
            fail "something went wrong"
          end
        }
      }

      it "handles the error" do
        expect(response[0]).to eq(500)
        expect(response[2]).to eq("application_handled")
      end

      context "500 handler does not halt" do
        let(:app_def) {
          Proc.new {
            handle 500 do |connection:|
              connection.body.write "application_handled"
            end

            action do
              fail "something went wrong"
            end
          }
        }

        it "calls the default 500 handler" do
          expect(response[0]).to eq(500)
          expect(response[2]).to eq("500 Server Error")
        end
      end
    end

    context "error handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle ArgumentError do |connection:|
            connection.body.write "application_handled_argument_error"
          end

          action do |connection|
            raise Kernel.const_get(connection.params[:error])
          end
        }
      }

      it "handles matching errors" do
        response = call("/", params: { error: "ArgumentError" })

        expect(response[0]).to eq(200)
        expect(response[2]).to eq("application_handled_argument_error")
      end

      it "does not handle unmatching errors" do
        response = call("/", params: { error: "RuntimeError" })

        expect(response[0]).to eq(500)
        expect(response[2]).to eq("500 Server Error")
      end
    end
  end
end
