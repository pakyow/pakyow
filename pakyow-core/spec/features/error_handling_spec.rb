RSpec.describe "error handling" do
  include_context "testable app"

  context "when an error is triggered" do
    context "and a handler is defined by name" do
      def define
        Pakyow::App.define do
          router do
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
        expect(call[2].body.read).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined by code" do
      def define
        Pakyow::App.define do
          router do
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
        expect(call[2].body.read).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined on a route as well as the router" do
      def define
        Pakyow::App.define do
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
        end
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found from route")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a parent router" do
      def define
        Pakyow::App.define do
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
        end
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found from parent")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is defined in a sibling router" do
      def define
        Pakyow::App.define do
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
        end
      end

      it "does not handle the error" do
        expect(call[2].body).to be_empty
      end

      it "still sets the response code" do
        expect(call[0]).to eq(404)
      end
    end
  end

  context "when an exception occurs" do
    context "and a handler is defined for the exception" do
      def define
        Pakyow::App.define do
          router do
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
        expect(call[2].body.read).to eq("handled exception")
      end

      it "sets the response code" do
        expect(call[0]).to eq(401)
      end

      context "and another error of the same type occurs" do
        def define
          Pakyow::App.define do
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
          end
        end

        include_context "suppressed output"

        it "does not handle that error" do
          expect(call[0]).to eq(401)
          expect(call("/foo")[0]).to eq(500)
        end
      end
    end
  end

  context "when the framework triggers a 404" do
    context "and a handler is defined" do
      def define
        Pakyow::App.define do
          router do
            handle 404 do
              send "not found"
            end
          end
        end
      end

      it "handles the error" do
        expect(call[2].body.read).to eq("not found")
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end

    context "and a handler is not defined" do
      def define
        Pakyow::App.define do
        end
      end

      it "sets the response code" do
        expect(call[0]).to eq(404)
      end
    end
  end

  context "when the framework triggers a 500" do
    context "and a handler is defined" do
      def define
        Pakyow::App.define do
          router do
            handle 500 do
              send "boom"
            end

            default do
              fail
            end
          end
        end
      end

      include_context "suppressed output"

      it "handles the error" do
        expect(call[2].body.read).to eq("boom")
      end

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end

    context "and a handler is not defined" do
      def define
        Pakyow::App.define do
          router do
            default do
              fail
            end
          end
        end
      end

      include_context "suppressed output"

      it "sets the response code" do
        expect(call[0]).to eq(500)
      end
    end
  end
end
