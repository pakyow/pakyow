RSpec.describe "handling missing" do
  include_context "app"

  let(:response) {
    call("/")
  }

  describe "in the environment" do
    let(:mount_app) {
      false
    }

    it "returns the default missing response" do
      expect(response[0]).to eq(404)
      expect(response[2]).to eq("404 Not Found")
    end

    context "connection headers were modified but the connection was not halted" do
      let(:env_def) {
        Proc.new {
          action do |connection|
            connection.headers["foo"] = "bar"
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
          end
        }
      }

      it "returns the correct status" do
        expect(response[0]).to eq(404)
      end

      it "returns the default body" do
        expect(response[2]).to eq("404 Not Found")
      end
    end

    context "404 handler is defined on the environment" do
      let(:env_def) {
        Proc.new {
          handle 404 do |event, connection:|
            connection.body.write "foo"
            connection.halt
          end
        }
      }

      it "handles with the environment handler" do
        expect(response[2]).to eq("foo")
      end

      context "404 handler does not halt" do
        let(:env_def) {
          Proc.new {
            handle 404 do |event, connection:|
              connection.body.write "foo"
            end
          }
        }

        it "calls the default 404 handler" do
          expect(response[0]).to eq(404)
          expect(response[2]).to eq("404 Not Found")
        end
      end
    end
  end

  describe "in the application" do
    it "returns the default missing response" do
      expect(response[0]).to eq(404)
      expect(response[2]).to eq("404 Not Found")
    end

    context "connection body was modified but the connection was not halted" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.body.write "foo"
          end
        }
      }

      it "returns the correct status" do
        expect(response[0]).to eq(404)
      end

      it "returns the default body" do
        expect(response[2]).to eq("404 Not Found")
      end
    end

    context "404 handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle 404 do |event, connection:|
            connection.body.write "foo"
            connection.halt
          end
        }
      }

      it "handles with the application handler" do
        expect(response[2]).to eq("foo")
      end

      context "404 handler does not halt" do
        let(:app_def) {
          Proc.new {
            handle 404 do |event, connection:|
              connection.body.write "foo"
            end
          }
        }

        it "calls the default 404 handler" do
          expect(response[0]).to eq(404)
          expect(response[2]).to eq("404 Not Found")
        end
      end
    end
  end
end
