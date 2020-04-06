RSpec.describe "handling status code events during a request lifecycle" do
  include_context "app"

  describe "triggering a status code event by name" do
    context "triggering on the environment" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            trigger :unauthorized, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the environment" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                trigger :unauthorized, connection: connection
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                trigger :unauthorized, connection: connection
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the application" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            trigger :unauthorized, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the application" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                trigger :unauthorized, connection: connection
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                trigger :unauthorized, connection: connection
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the environment connection" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            connection.trigger :unauthorized
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the environment connection" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                connection.trigger :unauthorized
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                connection.trigger :unauthorized
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the application connection" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.trigger :unauthorized
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the environment connection" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                connection.trigger :unauthorized
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                connection.trigger :unauthorized
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end
  end

  describe "triggering a status code event by code" do
    context "triggering on the environment" do
      context "handler is defined on the environment" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                trigger 401, connection: connection
              end
            }
          }

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                trigger 401, connection: connection
              end
            }
          }

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the application" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            trigger 401
          end
        }
      }

      context "handler is defined on the application" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                trigger 401, connection: connection
              end
            }
          }

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                trigger 401, connection: connection
              end
            }
          }

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the environment connection" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            connection.trigger 401
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the environment connection" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                connection.trigger 401
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              Pakyow.handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              Pakyow.action do |connection|
                connection.trigger 401
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end

    context "triggering on the application connection" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.trigger 401
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      context "handler is defined on the environment connection" do
        context "handler is defined by name" do
          let(:app_def) {
            Proc.new {
              handle :unauthorized do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                connection.trigger 401
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end

        context "handler is defined by code" do
          let(:app_def) {
            Proc.new {
              handle 401 do |connection:|
                connection.body = "unauthorized"
              end

              action do |connection|
                connection.trigger 401
              end
            }
          }

          it "sets the response status" do
            expect(call("/")[0]).to eq(401)
          end

          it "handles the event" do
            expect(call("/")[2]).to eq("unauthorized")
          end
        end
      end
    end
  end

  describe "handling an event as a status by name" do
    context "handler is defined on the environment" do
      let(:app_def) {
        Proc.new {
          Pakyow.handle :foo, as: :unauthorized do |connection:|
            connection.body = "unauthorized"
          end

          Pakyow.action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.handle :foo, as: :unauthorized

            Pakyow.action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle :foo, as: :unauthorized do |connection:|
            connection.body = "unauthorized"
          end

          action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            handle :foo, as: :unauthorized

            action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the environment connection" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            connection.handle :foo, as: :unauthorized do
              connection.body = "unauthorized"
            end

            connection.trigger :foo
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.action do |connection|
              connection.handle :foo, as: :unauthorized
              connection.trigger :foo
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the application connection" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.handle :foo, as: :unauthorized do
              connection.body = "unauthorized"
            end

            connection.trigger :foo
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            action do |connection|
              connection.handle :foo, as: :unauthorized
              connection.trigger :foo
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end
  end

  describe "handling an event as a status by code" do
    context "handler is defined on the environment" do
      let(:app_def) {
        Proc.new {
          Pakyow.handle :foo, as: 401 do |connection:|
            connection.body = "unauthorized"
          end

          Pakyow.action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.handle :foo, as: 401

            Pakyow.action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle :foo, as: 401 do |connection:|
            connection.body = "unauthorized"
          end

          action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            handle :foo, as: 401

            action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the environment connection" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            connection.handle :foo, as: 401 do
              connection.body = "unauthorized"
            end

            connection.trigger :foo
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.action do |connection|
              connection.handle :foo, as: 401
              connection.trigger :foo
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end

    context "handler is defined on the application connection" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.handle :foo, as: 401 do
              connection.body = "unauthorized"
            end

            connection.trigger :foo
          end
        }
      }

      it "sets the response status" do
        expect(call("/")[0]).to eq(401)
      end

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            action do |connection|
              connection.handle :foo, as: 401
              connection.trigger :foo
            end
          }
        }

        it "sets the response status" do
          expect(call("/")[0]).to eq(401)
        end
      end
    end
  end

  describe "handling an event as a status in both the original handler and the status handler" do
    context "handler is defined on the environment" do
      let(:app_def) {
        Proc.new {
          Pakyow.handle :foo, as: 401 do |connection:|
            connection.body.write "unauthorized"
          end

          Pakyow.handle 401 do |connection:|
            connection.body.write "401"
          end

          Pakyow.action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized401")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.handle :foo, as: 401

            Pakyow.handle 401 do |connection:|
              connection.body.write "401"
            end

            Pakyow.action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "handles the event" do
          expect(call("/")[2]).to eq("401")
        end
      end
    end

    context "handler is defined on the application" do
      let(:app_def) {
        Proc.new {
          handle :foo, as: 401 do |connection:|
            connection.body.write "unauthorized"
          end

          handle 401 do |connection:|
            connection.body.write "401"
          end

          action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized401")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            handle :foo, as: 401

            handle 401 do |connection:|
              connection.body.write "401"
            end

            action do |connection|
              trigger :foo, connection: connection
            end
          }
        }

        it "handles the event" do
          expect(call("/")[2]).to eq("401")
        end
      end
    end

    context "handler is defined on the environment connection" do
      let(:app_def) {
        Proc.new {
          Pakyow.action do |connection|
            connection.handle :foo, as: 401 do
              connection.body.write "unauthorized"
            end

            connection.handle 401 do |connection:|
              connection.body.write "401"
            end

            connection.trigger :foo
          end
        }
      }

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized401")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            Pakyow.action do |connection|
              connection.handle :foo, as: 401

              connection.handle 401 do |connection:|
                connection.body.write "401"
              end

              connection.trigger :foo
            end
          }
        }

        it "handles the event" do
          expect(call("/")[2]).to eq("401")
        end
      end
    end

    context "handler is defined on the application connection" do
      let(:app_def) {
        Proc.new {
          action do |connection|
            connection.handle :foo, as: 401 do
              connection.body.write "unauthorized"
            end

            connection.handle 401 do |connection:|
              connection.body.write "401"
            end

            connection.trigger :foo
          end
        }
      }

      it "handles the event" do
        expect(call("/")[2]).to eq("unauthorized401")
      end

      context "handler is defined without a block" do
        let(:app_def) {
          Proc.new {
            action do |connection|
              connection.handle :foo, as: 401

              connection.handle 401 do |connection:|
                connection.body.write "401"
              end

              connection.trigger :foo
            end
          }
        }

        it "handles the event" do
          expect(call("/")[2]).to eq("401")
        end
      end
    end
  end
end
