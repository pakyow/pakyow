require "pakyow/data/container"

RSpec.describe "finalizing a container" do
  let :container do
    Pakyow::Data::Container.new(
      connection: connection,
      sources: [source],
      objects: []
    )
  end

  let :connection do
    Class.new do
      module Commands
      end

      module DatasetMethods
      end

      def self.adapter
        nil
      end

      def self.types
        {}
      end
    end
  end

  let :source do
    Class.new(Pakyow::Data::Sources::Relational) do
      attribute :foo
    end
  end

  context "container has already been finalized" do
    before do
      container.finalize_associations!([])
      container.finalize_sources!([])
    end

    it "does not fail" do
      expect {
        container.finalize_associations!([])
        container.finalize_sources!([])
      }.not_to raise_error
    end
  end
end
