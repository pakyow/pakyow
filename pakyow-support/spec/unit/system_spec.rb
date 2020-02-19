require "pakyow/support/system"

RSpec.describe Pakyow::Support::System do
  before do
    allow(File).to receive(:expand_path).with(".").and_return("/pwd")
    allow(File).to receive(:expand_path).with("../../../../../", anything).and_return("/framework")
    allow(Bundler).to receive(:bundle_path).and_return(Pathname.new("/bundle"))
    allow(Gem).to receive(:dir).and_return("/gemdir")
  end

  shared_examples :memoized_pathname do
    it "returns a pathname" do
      expect(call).to be_instance_of(Pathname)
    end

    it "memoizes" do
      expect(call).to be(call)
    end
  end

  shared_examples :memoized_string do
    it "returns a string" do
      expect(call).to be_instance_of(String)
    end

    it "memoizes" do
      expect(call).to be(call)
    end
  end

  describe "#current_path" do
    def call
      subject.current_path
    end

    it "expands ." do
      expect(call.to_s).to eq("/pwd")
    end

    it_behaves_like :memoized_pathname
  end

  describe "#current_path_string" do
    def call
      subject.current_path_string
    end

    it "stringifies current_path" do
      expect(call).to eq(subject.current_path.to_s)
    end

    it_behaves_like :memoized_string
  end

  describe "#gemfile_path" do
    def call
      subject.gemfile_path
    end

    it "is a path to the gemfile, relative to current_path" do
      expect(call.to_s).to eq("/pwd/Gemfile")
    end

    it_behaves_like :memoized_pathname
  end

  describe "#gemfile_path_string" do
    def call
      subject.gemfile_path_string
    end

    it "stringifies gemfile_path" do
      expect(call).to eq(subject.gemfile_path.to_s)
    end

    it_behaves_like :memoized_string
  end

  describe "#gemfile?" do
    before do
      allow(subject).to receive(:gemfile_path).and_return(gemfile_path_double)
    end

    let(:gemfile_path_double) {
      instance_double(Pathname, exist?: true)
    }

    it "checks if the gemfile exists" do
      expect(subject.gemfile?).to be(true)
    end
  end

  describe "#bundler_gem_path" do
    def call
      subject.bundler_gem_path
    end

    it "is a path to the bundler gems" do
      expect(call.to_s).to eq("/bundle/bundler/gems")
    end

    it_behaves_like :memoized_pathname
  end

  describe "#bundler_gem_path_string" do
    def call
      subject.bundler_gem_path_string
    end

    it "stringifies bundler_gem_path" do
      expect(call).to eq(subject.bundler_gem_path.to_s)
    end

    it_behaves_like :memoized_string
  end

  describe "#local_framework_path" do
    def call
      subject.local_framework_path
    end

    it "is a path to the local framework" do
      expect(call.to_s).to eq("/framework")
    end

    it_behaves_like :memoized_pathname
  end

  describe "#local_framework_path_string" do
    def call
      subject.local_framework_path_string
    end

    it "stringifies local_framework_path" do
      expect(call).to eq(subject.local_framework_path.to_s)
    end

    it_behaves_like :memoized_string
  end

  describe "#ruby_gem_path" do
    def call
      subject.ruby_gem_path
    end

    it "is a path to ruby gems" do
      expect(call.to_s).to eq("/gemdir/gems")
    end

    it_behaves_like :memoized_pathname
  end

  describe "#ruby_gem_path_string" do
    def call
      subject.ruby_gem_path_string
    end

    it "stringifies ruby_gem_path" do
      expect(call).to eq(subject.ruby_gem_path.to_s)
    end

    it_behaves_like :memoized_string
  end

  describe "#available_port" do
    before do
      allow(TCPServer).to receive(:new).with("127.0.0.1", 0).and_return(server)
    end

    let(:server) {
      instance_double(TCPServer, close: nil, addr: addr)
    }

    let(:addr) {
      ["127.0.0.1", 4242]
    }

    it "initializes a tcp server" do
      described_class.available_port

      expect(TCPServer).to have_received(:new).with("127.0.0.1", 0)
    end

    it "returns the address port from the server" do
      expect(described_class.available_port).to eq(4242)
    end

    it "closes the server" do
      described_class.available_port

      expect(server).to have_received(:close)
    end

    context "getting the address fails" do
      before do
        allow(server).to receive(:addr).and_raise(RuntimeError)
      end

      it "closes the server" do
        expect {
          described_class.available_port
        }.to raise_error(RuntimeError)

        expect(server).to have_received(:close)
      end
    end
  end

  context "included into a class" do
    subject { Class.new.tap { |c| c.include described_class }.new }

    shared_examples :private_behavior do
      it "is private" do
        expect { subject.public_send(method) }.to raise_error(NoMethodError)
        expect { subject.send(method) }.to_not raise_error(NoMethodError)
      end

      it "behaves like the class method" do
        expect(subject.send(method)).to eq(described_class.public_send(method))
      end
    end

    describe "#current_path" do
      let(:method) { :current_path }
      it_behaves_like :private_behavior
    end

    describe "#current_path_string" do
      let(:method) { :current_path_string }
      it_behaves_like :private_behavior
    end

    describe "#gemfile_path" do
      let(:method) { :gemfile_path }
      it_behaves_like :private_behavior
    end

    describe "#gemfile_path_string" do
      let(:method) { :gemfile_path_string }
      it_behaves_like :private_behavior
    end

    describe "#gemfile?" do
      let(:method) { :gemfile? }
      it_behaves_like :private_behavior
    end

    describe "#bundler_gem_path" do
      let(:method) { :bundler_gem_path }
      it_behaves_like :private_behavior
    end

    describe "#bundler_gem_path_string" do
      let(:method) { :bundler_gem_path_string }
      it_behaves_like :private_behavior
    end

    describe "#local_framework_path" do
      let(:method) { :local_framework_path }
      it_behaves_like :private_behavior
    end

    describe "#local_framework_path_string" do
      let(:method) { :local_framework_path_string }
      it_behaves_like :private_behavior
    end

    describe "#ruby_gem_path" do
      let(:method) { :ruby_gem_path }
      it_behaves_like :private_behavior
    end

    describe "#ruby_gem_path_string" do
      let(:method) { :ruby_gem_path_string }
      it_behaves_like :private_behavior
    end

    describe "#available_port" do
      let(:method) { :ruby_gem_path_string }
      it_behaves_like :private_behavior
    end
  end
end
