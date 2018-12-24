require "pakyow/realtime/server/adapters/memory"

RSpec.describe Pakyow::Realtime::Server::Adapter::Memory do
  describe "#serialize" do
    let :instance do
      described_class.new(nil, nil)
    end

    it "serializes the correct number of ivars" do
      expect(instance.serialize.keys.count).to eq(3)
    end

    it "serializes @socket_ids_by_channel" do
      expect(instance.serialize[:@socket_ids_by_channel]).to be_instance_of(Concurrent::Hash)
    end

    it "serializes @channels_by_socket_id" do
      expect(instance.serialize[:@channels_by_socket_id]).to be_instance_of(Concurrent::Hash)
    end

    it "serializes @socket_instances_by_socket_id" do
      expect(instance.serialize[:@socket_instances_by_socket_id]).to be_instance_of(Concurrent::Hash)
    end
  end
end
