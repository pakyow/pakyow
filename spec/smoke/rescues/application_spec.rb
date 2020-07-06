require "smoke_helper"

RSpec.describe "rescuing the application", smoke: true do
  context "error occurs before setup" do
    before do
      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"sqlite3\"")
      end

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test do
            on :setup do
              fail "something went wrong"
            end
          end
        SOURCE
      end

      boot
    end

    let(:response) {
      http.get("http://localhost:#{port}/")
    }

    context "running in development" do
      let(:environment) {
        :development
      }

      it "responds 500" do
        expect(response.status).to eq(500)
      end

      it "responds with a nice error" do
        expect(response.body.to_s).to include_sans_whitespace(
          <<~HTML
            <article data-b="pw_error">
              <header>
                <h1 data-b="name">Application error</h1>

                <section data-b="message"><p>something went wrong</p>
          HTML
        )
      end
    end

    context "running in production" do
      let(:environment) {
        :production
      }

      let(:envars) {
        {
          "SECRET" => "sekret",
          "DATABASE_URL" => "sqlite://database/production.db"
        }
      }

      it "responds 500" do
        expect(response.status).to eq(500)
      end

      it "responds with a default error" do
        expect(response.body.to_s).to include_sans_whitespace(
          <<~HTML
            <main>
              <p>
                <strong>500 (Server Error)</strong>
          HTML
        )
      end
    end
  end
end
