require "pakyow/runnable/formation"

RSpec.describe Pakyow::Runnable::Formation do
  describe "::parse" do
    let(:parsed) {
      described_class.parse(formation_string)
    }

    context "formation specifies a single top-level service" do
      let(:formation_string) {
        "environment.server=1"
      }

      it "parses" do
        expect(parsed.each.count).to eq(1)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:environment)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:server)
        expect(count).to eq(1)
      end
    end

    context "formation specifies multiple top-level services" do
      let(:formation_string) {
        "environment.server=1,environment.foo=2,environment.bar=3"
      }

      it "parses" do
        expect(parsed.each.count).to eq(3)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:environment)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:server)
        expect(count).to eq(1)

        service, count = parsed.each.to_a[1]
        expect(service).to eq(:foo)
        expect(count).to eq(2)

        service, count = parsed.each.to_a[2]
        expect(service).to eq(:bar)
        expect(count).to eq(3)
      end
    end

    context "formation specifies multiple top-level and deeply nested services" do
      let(:formation_string) {
        "supervisor.environment=2,supervisor.environment.server=42,supervisor.environment.application.thing=3,supervisor.watcher=1"
      }

      it "parses" do
        expect(parsed.each.count).to eq(2)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:supervisor)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:environment)
        expect(count).to eq(2)

        service, count = parsed.each.to_a[1]
        expect(service).to eq(:watcher)
        expect(count).to eq(1)
      end

      describe "nested formation" do
        it "parses" do
          expect(parsed.each_formation.to_a[0].each.count).to eq(2)
        end

        it "sets the container" do
          expect(parsed.each_formation.to_a[0].container).to eq(:environment)
        end

        it "sets the services" do
          service, count = parsed.each_formation.to_a[0].each.to_a[0]
          expect(service).to eq(:server)
          expect(count).to eq(42)
        end
      end

      describe "deeply nested formation" do
        it "parses" do
          expect(parsed.each_formation.to_a[0].each_formation.to_a[0].each.count).to eq(1)
        end

        it "sets the container" do
          expect(parsed.each_formation.to_a[0].each_formation.to_a[0].container).to eq(:application)
        end

        it "sets the services" do
          service, count = parsed.each_formation.to_a[0].each_formation.to_a[0].each.to_a[0]
          expect(service).to eq(:thing)
          expect(count).to eq(3)
        end
      end
    end

    context "formation specifies a single nested service" do
      let(:formation_string) {
        "supervisor.environment.server=42"
      }

      it "parses" do
        expect(parsed.each.count).to eq(1)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:supervisor)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:environment)
        expect(count).to eq(nil)
      end

      describe "nested formation" do
        it "parses" do
          expect(parsed.each_formation.to_a[0].each.count).to eq(1)
        end

        it "sets the container" do
          expect(parsed.each_formation.to_a[0].container).to eq(:environment)
        end

        it "sets the services" do
          service, count = parsed.each_formation.to_a[0].each.to_a[0]
          expect(service).to eq(:server)
          expect(count).to eq(42)
        end
      end
    end

    context "formation specifies a single nested service and a specific count of the top-level service" do
      let(:formation_string) {
        "supervisor.environment.server=42,supervisor.environment=2"
      }

      it "parses" do
        expect(parsed.each.count).to eq(1)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:supervisor)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:environment)
        expect(count).to eq(2)
      end

      describe "nested formation" do
        it "parses" do
          expect(parsed.each_formation.to_a[0].each.count).to eq(1)
        end

        it "sets the container" do
          expect(parsed.each_formation.to_a[0].container).to eq(:environment)
        end

        it "sets the services" do
          service, count = parsed.each_formation.to_a[0].each.to_a[0]
          expect(service).to eq(:server)
          expect(count).to eq(42)
        end
      end
    end

    context "formation specifies services for two top-level containers" do
      let(:formation_string) {
        "supervisor.foo=1,environment.server=1"
      }

      it "fails" do
        expect {
          parsed
        }.to raise_error(Pakyow::FormationError, "`supervisor.foo=1,environment.server=1' is an invalid formation because it defines multiple top-level containers ([:supervisor, :environment])")
      end
    end

    context "formation is specified with extra whitespace" do
      let(:formation_string) {
        "  environment.   server=1,        environment.foo=2,environment . bar    =3 "
      }

      it "parses" do
        expect(parsed.each.count).to eq(3)
      end

      it "sets the container" do
        expect(parsed.container).to eq(:environment)
      end

      it "sets the services" do
        service, count = parsed.each.to_a[0]
        expect(service).to eq(:server)
        expect(count).to eq(1)

        service, count = parsed.each.to_a[1]
        expect(service).to eq(:foo)
        expect(count).to eq(2)

        service, count = parsed.each.to_a[2]
        expect(service).to eq(:bar)
        expect(count).to eq(3)
      end
    end
  end

  describe "::build" do
    let(:container) {
      :foo
    }

    it "yields a formation instance" do
      expect { |block|
        described_class.build(container, &block)
      }.to yield_with_args(instance_of(described_class))
    end

    it "returns the formation instance" do
      expect(described_class.build(container)).to be_instance_of(described_class)
    end

    it "creates a formation instance for the container" do
      expect(described_class.build(container).container).to eq(container)
    end
  end

  describe "::all" do
    let(:all) {
      described_class.all(3)
    }

    it "returns an all formation" do
      expect(all.service?(:all)).to be(true)
      expect(all.count(:all)).to eq(3)
    end
  end

  describe "#run" do
    let(:services) {
      subject.each.to_a
    }

    it "adds services with a count" do
      subject.run :foo, 1

      expect(services[0][0]).to eq(:foo)
      expect(services[0][1]).to eq(1)
    end

    it "adds services without a count" do
      subject.run :bar

      expect(services[0][0]).to eq(:bar)
      expect(services[0][1]).to eq(nil)
    end
  end

  describe "#<<" do
    before do
      subject << nested
    end

    let(:nested) {
      described_class.build(:nested) { |formation| formation.run(:foo, 1) }
    }

    it "adds a nested formation" do
      expect(subject.formation(:nested)).to be(nested)
    end
  end

  describe "#build" do
    before do
      subject.build(:nested) { |formation| formation.run(:foo, 1) }
    end

    it "builds a nested formation" do
      expect(subject.formation(:nested)).to be_instance_of(described_class)
      expect(subject.formation(:nested).service?(:foo)).to be(true)
      expect(subject.formation(:nested).count(:foo)).to eq(1)
    end
  end

  describe "#merge!" do
    before do
      subject.run :foo, 1
      subject.run :bar, 2
      subject.merge!(mergeable)
    end

    let(:mergeable) {
      described_class.build(:mergeable) { |formation|
        formation.run :foo, 2
        formation.run :baz, 3
        formation << nested
      }
    }

    let(:nested) {
      described_class.build(:nested) { |formation| formation.run(:foo_nested, 42) }
    }

    it "merges services" do
      expect(subject.service?(:foo)).to be(true)
      expect(subject.count(:foo)).to eq(2)

      expect(subject.service?(:bar)).to be(true)
      expect(subject.count(:bar)).to eq(2)

      expect(subject.service?(:baz)).to be(true)
      expect(subject.count(:baz)).to eq(3)
    end

    it "merges formations" do
      expect(subject.formation(:nested)).to be(nested)
    end
  end

  describe "#service?" do
    before do
      subject.run :foo
    end

    context "service exists" do
      it "returns true" do
        expect(subject.service?(:foo)).to be(true)
      end
    end

    context "service does not exist" do
      it "returns false" do
        expect(subject.service?(:bar)).to be(false)
      end
    end
  end

  describe "#count" do
    before do
      subject.run :foo, 1
    end

    it "returns the count for the service" do
      expect(subject.count(:foo)).to eq(1)
    end

    context "service does not exist" do
      it "returns nil" do
        expect(subject.count(:bar)).to eq(nil)
      end
    end
  end

  describe "#formation?" do
    before do
      subject.build :foo
    end

    context "formation exists" do
      it "returns true" do
        expect(subject.formation?(:foo)).to be(true)
      end
    end

    context "formation does not exist" do
      it "returns false" do
        expect(subject.formation?(:bar)).to be(false)
      end
    end
  end

  describe "#formation" do
    before do
      subject << nested
    end

    let(:nested) {
      described_class.build(:foo)
    }

    it "returns the formation for the container" do
      expect(subject.formation(:foo)).to be(nested)
    end

    context "formation does not exist" do
      it "returns nil" do
        expect(subject.formation(:bar)).to be(nil)
      end
    end
  end

  describe "#each" do
    before do
      subject.run :foo, 1
      subject.run :bar, nil
      subject.run :baz, 3
    end

    it "yields each service and count" do
      services = []
      counts = []

      subject.each do |service, count|
        services << service
        counts << count
      end

      expect(services).to eq([:foo, :bar, :baz])
      expect(counts).to eq([1, nil, 3])
    end

    context "called without a block" do
      it "returns an enumerator" do
        expect(subject.each.count).to eq(3)
      end
    end
  end

  describe "#each_service" do
    before do
      subject.run :foo, 1
      subject.run :bar, nil
      subject.run :baz, 3
    end

    it "yields each service" do
      services = []

      subject.each_service do |service|
        services << service
      end

      expect(services).to eq([:foo, :bar, :baz])
    end

    context "called without a block" do
      it "returns an enumerator" do
        expect(subject.each_service.count).to eq(3)
      end
    end
  end

  describe "#each_formation" do
    before do
      subject.build :foo
      subject.build :bar
    end

    it "yields each nested formation" do
      containers = []

      subject.each_formation do |formation|
        containers << formation.container
      end

      expect(containers).to eq([:foo, :bar])
    end

    context "called without a block" do
      it "returns an enumerator" do
        expect(subject.each_formation.count).to eq(2)
      end
    end
  end

  describe "#to_s" do
    before do
      subject.run :foo, 1
      subject.run :bar, 2

      subject.build :nested_1 do |formation|
        formation.run :foo, 3
      end

      subject.build :nested_2 do |formation|
        formation.build :deeply_nested do |deeply_nested|
          deeply_nested.run :baz
          deeply_nested.run :qux, 5
        end
      end
    end

    let(:subject) {
      described_class.build(:toplevel)
    }

    it "returns the formation as a string" do
      expect(subject.to_s).to eq("toplevel.foo=1,toplevel.bar=2,toplevel.nested_1.foo=3,toplevel.nested_2.deeply_nested.baz,toplevel.nested_2.deeply_nested.qux=5")
    end

    describe "the returned string" do
      it "is parsable" do
        expect(described_class.parse(subject.to_s).to_s).to eq("toplevel.foo=1,toplevel.bar=2,toplevel.nested_1,toplevel.nested_2,nested_1.foo=3,nested_2.deeply_nested,deeply_nested.baz,deeply_nested.qux=5")
      end
    end
  end

  describe "equality" do
    context "same services, same container" do
      let(:one) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
        }
      }

      let(:two) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
        }
      }

      it "is true" do
        expect(one).to eq(two)
      end
    end

    context "same services, different container" do
      let(:one) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
        }
      }

      let(:two) {
        described_class.build(:baz) { |formation|
          formation.run :bar, 1
        }
      }

      it "is false" do
        expect(one).not_to eq(two)
      end
    end

    context "same services, same container, same formations" do
      let(:one) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
          formation << nested_1
        }
      }

      let(:two) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
          formation << nested_2
        }
      }

      let(:nested_1) {
        described_class.build(:nested) { |formation| formation.run(:foo, 1) }
      }

      let(:nested_2) {
        described_class.build(:nested) { |formation| formation.run(:foo, 1) }
      }

      it "is true" do
        expect(one).to eq(two)
      end
    end

    context "same services, same container, different formations" do
      let(:one) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
          formation << nested_1
        }
      }

      let(:two) {
        described_class.build(:foo) { |formation|
          formation.run :bar, 1
          formation << nested_2
        }
      }

      let(:nested_1) {
        described_class.build(:nested) { |formation| formation.run(:foo, 1) }
      }

      let(:nested_2) {
        described_class.build(:nested) { |formation| formation.run(:bar, 1) }
      }

      it "is false" do
        expect(one).not_to eq(two)
      end
    end
  end
end
