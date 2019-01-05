RSpec.describe Pakyow::Actions::RequestParser do
  let :app do
    instance_double(Pakyow::App)
  end

  let :action do
    Pakyow::Actions::RequestParser.new
  end

  let :connection do
    Pakyow::Connection.new(app, env)
  end

  let :env do
    {
      "CONTENT_TYPE" => "text/foo",
      "rack.input" => StringIO.new(body)
    }
  end

  let :body do
    "foo"
  end

  context "parser is registered for the request type" do
    before do
      Pakyow.parse_request "text/foo" do |body|
        @called = true
        body.upcase
      end
    end

    context "connection body is not empty" do
      it "parses the body" do
        action.call(connection)
        expect(@called).to be(true)
      end

      it "sets the parsed body on the connection" do
        action.call(connection)
        expect(connection.parsed_body).to eq("FOO")
      end

      context "parsing fails" do
        before do
          Pakyow.parse_request "text/foo" do |body|
            raise error
          end

          allow(Pakyow.logger).to receive(:houston)
        end

        let :error do
          StandardError.new("failed")
        end

        it "logs the error" do
          expect(Pakyow.logger).to receive(:houston).with(error)

          catch :halt do
            action.call(connection)
          end
        end

        it "sets the connection status to 400" do
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(400)
        end

        it "halts the connection" do
          catch :halt do
            action.call(connection)
          end

          expect(connection.halted?).to be(true)
        end
      end
    end

    context "connection body is empty" do
      let :body do
        ""
      end

      it "does not attempt to parse" do
        catch :halt do
          action.call(connection)
        end

        expect(@called).to be(nil)
      end
    end
  end

  context "parser is registered, but not for the type" do
    before do
      Pakyow.parse_request "text/bar" do |body|
        @called = true
      end
    end

    it "does not attempt to parse" do
      catch :halt do
        action.call(connection)
      end

      expect(@called).to be(nil)
    end
  end

  context "no parsers are registered" do
    it "does not attempt to parse" do
      catch :halt do
        action.call(connection)
      end

      expect(@called).to be(nil)
    end
  end
end
