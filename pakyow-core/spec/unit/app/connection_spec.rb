require_relative "./connection/shared_examples/values"
require_relative "./connection/shared_examples/verifier"

require "pakyow/application/connection"
require "pakyow/application/connection/session/cookie"

require "pakyow/support/deep_dup"

RSpec.describe Pakyow::Application::Connection do
  using Pakyow::Support::DeepDup

  let :connection do
    described_class.new(app, environment_connection)
  end

  let :app do
    instance_double(
      Pakyow::Application,
      config: Pakyow::Application.config.deep_dup,
      session_object: Pakyow::Application::Connection::Session::Cookie,
      session_options: Pakyow::Application.config.session.cookie.deep_dup,
      rescued?: false
    )
  end

  let :environment_connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", path, nil, Protocol::HTTP::Headers.new([])
    )
  end

  let :path do
    "/"
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:output, level: 2, verbose!: nil)
    )
  end

  describe "#initialize" do
    it "calls the initialize hooks" do
      before, after = nil

      described_class.before "initialize" do
        before = true
      end

      described_class.after "initialize" do
        after = true
      end

      connection

      expect(before).to be(true)
      expect(after).to be(true)
    end

    context "application is rescued" do
      before do
        allow(app).to receive(:rescued?).and_return(true)
      end

      it "does not call the initialize hooks" do
        before, after = nil

        described_class.before "initialize" do
          before = true
        end

        described_class.after "initialize" do
          after = true
        end

        connection

        expect(before).to be(nil)
        expect(after).to be(nil)
      end
    end
  end

  describe "#initialize_dup" do
    it "calls the dup hooks" do
      called = false
      described_class.on :dup do
        called = true
      end

      connection.dup
      expect(called).to be(true)
    end
  end

  describe "#method" do
    it "returns the expected value" do
      expect(connection.method).to eq(:get)
    end
  end

  describe "#path" do
    before do
      allow(app).to receive(:mount_path).and_return("/foo")
    end

    let :path do
      "/foo/bar"
    end

    it "returns the request path relative to the app" do
      expect(connection.path).to eq("/bar")
    end
  end

  it_behaves_like :connection_values
  it_behaves_like :connection_verifier
end
