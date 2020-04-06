RSpec.describe "handling events during a request lifecycle" do
  include_context "app"

  let(:app_def) {
    local = self

    Proc.new {
      Pakyow.handle :foo do |event, connection:|
        local.handled = { event: event, connection: connection }
      end

      Pakyow.action do |connection|
        trigger :foo, connection: connection
      end
    }
  }

  attr_accessor :handled

  after do
    @handled = nil
  end

  it "handles environment events with the environment handler" do
    call("/")

    expect(@handled).to_not be(nil)
  end

  it "passes keyword arguments to the handler" do
    call("/")

    expect(@handled[:connection]).to be_instance_of(Pakyow::Connection)
  end

  describe "the handling context" do
    let(:app_def) {
      local = self

      Proc.new {
        Pakyow.handle do
          local.handled = self
        end

        Pakyow.action do
          trigger :foo
        end
      }
    }

    it "handles in context of the environment" do
      call("/")

      expect(@handled).to be(Pakyow)
    end
  end

  context "event is triggered on an application" do
    let(:app_def) {
      local = self
      Proc.new {
        Pakyow.handle :foo do
          local.handled = true
        end

        action do
          trigger :foo
        end
      }
    }

    it "handles application events with the environment handler" do
      call("/")

      expect(@handled).to be(true)
    end

    context "application handler is defined" do
      before do
        @handled = []
      end

      let(:app_def) {
        local = self

        Proc.new {
          Pakyow.handle :foo do
            local.handled << :environment_foo
          end

          Pakyow.handle :bar do
            local.handled << :environment_bar
          end

          handle :foo do
            local.handled << :application_foo
          end

          action do |connection|
            trigger connection.params[:event].to_sym
          end
        }
      }

      it "handles matching application events with the first handler" do
        call("/", params: { event: :foo })

        expect(@handled).to eq([:application_foo])
      end

      it "handles other application events with the environment handler" do
        call("/", params: { event: :bar })

        expect(@handled).to eq([:environment_bar])
      end

      context "application handler halts" do
        let(:app_def) {
          local = self

          Proc.new {
            Pakyow.handle :foo do
              local.handled << :environment_foo
            end

            handle :foo do
              local.handled << :application_foo
              throw :halt
            end

            action do |connection|
              trigger connection.params[:event].to_sym
            end
          }
        }

        it "calls only the application handler" do
          call("/", params: { event: :foo })

          expect(@handled).to eq([:application_foo])
        end
      end

      describe "the handling context" do
        let(:app_def) {
          local = self

          Proc.new {
            handle do
              local.handled = self
            end

            action do
              trigger :foo
            end
          }
        }

        it "handles in context of the application" do
          call("/")

          expect(@handled).to be(Pakyow.app(:test))
        end
      end

      describe "halting event handling" do
        before do
          @handled = []
        end

        let(:app_def) {
          local = self

          Proc.new {
            Pakyow.handle :foo do
              local.handled << :environment_foo
            end

            handle :foo do
              local.handled << :application_foo
              throw :halt
            end

            action do |connection|
              trigger connection.params[:event].to_sym
            end
          }
        }

        it "does not call environment handlers when halted in the application" do
          call("/", params: { event: :foo })

          expect(@handled).to eq([:application_foo])
        end
      end
    end
  end
end
