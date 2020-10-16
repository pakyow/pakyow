RSpec.describe "error handling" do
  include_context "app"

  context "when an error is triggered" do
    context "and a handler is defined by name" do
      let :app_def do
        Proc.new do
          controller do
            handle :not_found do
              send "not found"
            end

            default do
              trigger 404
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined by code" do
      let :app_def do
        Proc.new do
          controller do
            handle 404 do
              send "not found"
            end

            default do
              trigger :not_found
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined on a route as well as the controller" do
      let :app_def do
        Proc.new do
          controller do
            handle 404 do
              send "not found"
            end

            default do
              handle 404 do
                send "not found from route"
              end

              trigger 404
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("not found from route")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a parent controller" do
      let :app_def do
        Proc.new do
          controller :top do
            handle 404 do
              send "not found from parent"
            end

            group :foo do
              default do
                trigger 404
              end
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("not found from parent")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a nested parent controller" do
      let :app_def do
        Proc.new do
          controller :top do
            group :foo do
              handle 403 do
                send "forbidden from parent"
              end

              group :bar do
                default do
                  trigger 403
                end
              end
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("forbidden from parent")
      end

      it "sets the response code" do
        expect(call[0]).to eq(403)
      end
    end

    context "and a handler is defined in a sibling controller" do
      let :app_def do
        Proc.new do
          controller do
            handle 404 do
              send "not found from sibling"
            end
          end

          controller do
            default do
              trigger 404
            end
          end
        end
      end

      it "does not handle the error" do
        expect(call[2]).not_to eq("not found from sibling")
      end

      it "still sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is not defined" do
      let :app_def do
        Proc.new do
          controller do
            default do
              trigger 404

              # This should not be executed if `trigger` halts correctly.
              #
              connection.body = "foo"
            end
          end
        end
      end

      it "halts" do
        expect(call[2]).not_to eq("foo")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end
  end

  context "when an exception occurs" do
    context "and a handler is defined for the exception" do
      let :app_def do
        Proc.new do
          controller do
            handle StandardError, as: 401 do
              send "handled exception"
            end

            default do
              raise StandardError
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("handled exception")
      end

      it "sets the response code" do
        expect(call[0]).to eq(401)
      end

      context "and another error of the same type occurs" do
        let :app_def do
          Proc.new do
            controller :one do
              handle StandardError, as: 401 do
                send "handled exception"
              end

              default do
                raise StandardError
              end
            end

            controller :two do
              get "/foo" do
                raise StandardError
              end
            end
          end
        end

        let :allow_request_failures do
          true
        end

        include_context "suppressed output"

        it "does not handle that error" do
          expect(call[0]).to eq(401)
          expect(call("/foo")[0]).to eq(500)
        end
      end

      context "and a handler is defined for the exception in a parent controller" do
        let :app_def do
          Proc.new do
            controller :top do
              handle StandardError, as: 401 do
                send "handled exception from parent"
              end

              group :foo do
                default do
                  raise StandardError
                end
              end
            end
          end
        end

        it "handles the error" do
          expect(call[2]).to eq("handled exception from parent")
        end

        it "sets the response code" do
          expect(call[0]).to eq(401)
        end
      end

      context "and the handler accepts the error object" do
        let :app_def do
          Proc.new do
            controller do
              handle StandardError, as: 401 do |error|
                send error.to_s
              end

              default do
                raise StandardError
              end
            end
          end
        end

        it "is passed the error object" do
          expect(call[2]).to eq("StandardError")
        end
      end
    end

    context "and a blockless handler is defined for the exception" do
      let :app_def do
        Proc.new do
          controller do
            handle StandardError, as: 401

            default do
              raise StandardError
            end
          end
        end
      end

      it "sets the response code" do
        expect(call[0]).to eq(401)
      end
    end

    context "and a handler is not defined for the exception" do
      let :app_def do
        Proc.new do
          controller do
            default do
              raise StandardError
            end
          end
        end
      end

      let :allow_request_failures do
        true
      end

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end

      it "returns the default response" do
        expect(call[2]).to eq("500 Server Error")
      end
    end
  end

  context "when the framework triggers a 404" do
    context "and a global handler is defined" do
      let :app_def do
        Proc.new do
          handle 404 do |connection:|
            connection.body = "not found"
            connection.halt
          end
        end
      end

      it "handles the error" do
        expect(call[2]).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a global handler is not defined" do
      it "sets the response code" do
        expect(call[0]).to eq(404)
      end

      it "returns the default response" do
        expect(call[2]).to eq("404 Not Found")
      end
    end
  end

  context "when the framework triggers a 500" do
    context "and a global handler is defined" do
      let :app_def do
        Proc.new do
          handle 500 do |connection:|
            connection.body = "boom"
            connection.halt
          end

          controller do
            default do
              fail
            end
          end
        end
      end

      let :allow_request_failures do
        true
      end

      include_context "suppressed output"

      it "handles the error" do
        expect(call[0]).to eq(500)
        expect(call[2]).to eq("boom")
      end

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end

    context "and a global handler is defined for the error class" do
      let :app_def do
        Proc.new do
          handle ArgumentError, as: 406 do |connection:|
            connection.body = "boom"
          end

          controller do
            default do
              raise ArgumentError
            end
          end
        end
      end

      include_context "suppressed output"

      it "handles the error" do
        expect(call[2]).to eq("boom")
      end

      it "sets the response code" do
        expect(call[0]).to eq(406)
      end
    end

    context "and a global handler is not defined" do
      let :app_def do
        Proc.new do
          controller do
            default do
              fail
            end
          end
        end
      end

      let :allow_request_failures do
        true
      end

      include_context "suppressed output"

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end
  end

  describe "the handling context" do
    let :app_def do
      Proc.new do
        controller do
          handle 500 do |connection:|
            @state << "handler"
            connection.body = @state
          end

          default do
            @state = "route"
            trigger 500
          end
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "has access to route state" do
      expect(call[2]).to eq("routehandler")
    end
  end

  describe "rejecting from handlers" do
    let :app_def do
      Proc.new do
        controller do
          handle 500 do |connection:|
            @state << "handler2"
            connection.body = @state
          end

          handle 500 do
            @state << "handler1"
            reject
          end

          default do
            @state = "route"
            trigger 500
          end
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "passes off to the next handler" do
      expect(call[2]).to eq("routehandler1handler2")
    end
  end
end
