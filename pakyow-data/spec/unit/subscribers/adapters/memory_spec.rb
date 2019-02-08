require "pakyow/data/subscribers/adapters/memory"

RSpec.describe Pakyow::Data::Subscribers::Adapters::Memory do
  describe "#serialize" do
    let :instance do
      described_class.new(nil, nil)
    end

    it "serializes the correct number of ivars" do
      expect(instance.serialize.keys.count).to eq(4)
    end

    it "serializes @subscriptions_by_id" do
      expect(instance.serialize[:@subscriptions_by_id]).to be_instance_of(Concurrent::Hash)
    end

    it "serializes @subscription_ids_by_source" do
      expect(instance.serialize[:@subscription_ids_by_source]).to be_instance_of(Concurrent::Hash)
    end

    it "serializes @subscribers_by_subscription_id" do
      expect(instance.serialize[:@subscribers_by_subscription_id]).to be_instance_of(Concurrent::Hash)
    end
  end
end
