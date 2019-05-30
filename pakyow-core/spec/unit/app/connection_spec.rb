require_relative "./connection/shared_examples/values"
require_relative "./connection/shared_examples/verifier"

require "pakyow/app/connection/session/cookie"

require "pakyow/support/deep_dup"

RSpec.describe Pakyow::App::Connection do
  using Pakyow::Support::DeepDup

  let :connection do
    described_class.new(app, environment_connection)
  end

  let :app do
    instance_double(
      Pakyow::App,
      config: Pakyow::App.config.deep_dup,
      session_object: Pakyow::App::Connection::Session::Cookie,
      session_options: Pakyow::App.config.session.cookie.deep_dup
    )
  end

  let :environment_connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, Protocol::HTTP::Headers.new([])
    )
  end

  before do
    allow(Pakyow).to receive(:global_logger).and_return(double(:global_logger, level: 2))
  end

  describe "#initialize" do
    it "calls the initialize hooks" do
      before, after = nil

      described_class.before :initialize do
        before = true
      end

      described_class.after :initialize do
        after = true
      end

      connection

      expect(before).to be(true)
      expect(after).to be(true)
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

  it_behaves_like :connection_values
  it_behaves_like :connection_verifier
end
