RSpec.describe "error handling" do
  include_context "testable app"

  context "when an error is triggered" do
    context "and a handler is defined by name" do
      let :app_definition do
        Proc.new {
          router do
            handle :not_found do
              send "not found"
            end

            default do
              trigger 404
            end
          end
        }
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined by code" do
      let :app_definition do
        Proc.new {
          router do
            handle 404 do
              send "not found"
            end

            default do
              trigger :not_found
            end
          end
        }
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined on a route as well as the router" do
      let :app_definition do
        Proc.new {
          router do
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
        }
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found from route")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a parent router" do
      let :app_definition do
        Proc.new {
          router do
            handle 404 do
              send "not found from parent"
            end

            group :foo do
              default do
                trigger 404
              end
            end
          end
        }
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found from parent")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a nested parent router" do
      let :app_definition do
        Proc.new {
          router :top do
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
        }
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("forbidden from parent")
      end

      it "sets the response code" do
        expect(call[0]).to eq(403)
      end
    end

    context "and a handler is defined in a sibling router" do
      let :app_definition do
        Proc.new {
          router do
            handle 404 do
              send "not found from sibling"
            end
          end

          router do
            default do
              trigger 404
            end
          end
        }
      end

      it "does not handle the error" do
        expect(call[2].body.first).not_to eq("not found from sibling")
      end

      it "still sets the response code" do
        expect(call[0]).to eq(404)
      end
    end
  end

  context "when an exception occurs" do
    context "and a handler is defined for the exception" do
      let :app_definition do
        Proc.new {
          router do
            handle StandardError, as: 401 do
              send "handled exception"
            end

            default do
              raise StandardError
            end
          end
        }
      end

      it "handles the error" do
        expect(call[2].body.first).to eq("handled exception")
      end

      it "sets the response code" do
        expect(call[0]).to eq(401)
      end

      context "and another error of the same type occurs" do
        let :app_definition do
          Proc.new {
            router do
              handle StandardError, as: 401 do
                send "handled exception"
              end

              default do
                raise StandardError
              end
            end

            router do
              get "/foo" do
                raise StandardError
              end
            end
          }
        end

        include_context "suppressed output"

        it "does not handle that error" do
          expect(call[0]).to eq(401)
          expect(call("/foo")[0]).to eq(500)
        end
      end

      context "and a handler is defined for the exception in a parent router" do
        let :app_definition do
          Proc.new {
            router do
              handle StandardError, as: 401 do
                send "handled exception from parent"
              end

              group :foo do
                default do
                  raise StandardError
                end
              end
            end
          }
        end

        it "handles the error" do
          expect(call[2].body.read).to eq("handled exception from parent")
        end

        it "sets the response code" do
          expect(call[0]).to eq(401)
        end
      end
    end
  end

  context "when the framework triggers a 404" do
    context "and a global handler is defined" do
      let :app_definition do
        Proc.new {
          handle 404 do
            send "not found"
          end
        }
      end

      it "handles the error" do
        expect(call[2].body.first).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a global handler is not defined" do
      let :app_definition do
        Proc.new {
        }
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end
  end

  context "when the framework triggers a 500" do
    context "and a global handler is defined" do
      let :app_definition do
        Proc.new {
          handle 500 do
            send "boom"
          end

          router do
            default do
              fail
            end
          end
        }
      end

      include_context "suppressed output"

      it "handles the error" do
        expect(call[2].body.read).to eq("boom")
      end

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end

    context "and a global handler is defined for the error class" do
      let :app_definition do
        Proc.new {
          handle ArgumentError, as: 406 do
            send "boom"
          end

          router do
            default do
              raise ArgumentError
            end
          end
        }
      end

      include_context "suppressed output"

      it "handles the error" do
        expect(call[2].body.read).to eq("boom")
      end

      it "sets the response code" do
        expect(call[0]).to eq(406)
      end
    end

    context "and a global handler is not defined" do
      let :app_definition do
        Proc.new {
          router do
            default do
              fail
            end
          end
        }
      end

      include_context "suppressed output"

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end
  end

  describe "the handling context" do
    let :app_definition do
      Proc.new {
        router do
          handle 500 do
            @state << "handler"
            send @state
          end

          default do
            @state = "route"
            trigger 500
          end
        end
      }
    end

    it "has access to route state" do
      expect(call[2].body.read).to eq("routehandler")
    end
  end
end
