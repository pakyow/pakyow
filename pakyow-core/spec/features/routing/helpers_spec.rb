RSpec.describe "application helpers" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller do
        default do
          halt self.class.ancestors
        end
      end
    }
  end

  it "makes helpers available within a controller" do
    expect(call[0]).to eq(200)
    expect(call[2].body).to include(Pakyow::Routing::Helpers)
  end

  describe "configuring the app with another helper module" do
    after do
      Object.send(:remove_const, :MyHelpers)
    end

    let :app_definition do
      module MyHelpers
      end

      Proc.new {
        configure do
          config.app.helpers << MyHelpers
        end

        controller do
          default do
            halt self.class.ancestors
          end
        end
      }
    end

    it "makes helpers avaliable within a controller" do
      expect(call[0]).to eq(200)
      expect(call[2].body).to include(MyHelpers)
    end
  end
end
