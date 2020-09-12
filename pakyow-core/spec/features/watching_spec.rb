require "fileutils"

RSpec.describe "watching files from the environment", :restartable do
  before do
    allow(Pakyow).to receive(:restart)
  end

  let(:formation) {
    "environment.watcher=1"
  }

  def run(expected = 0)
    test_calls = []

    Pakyow.changed do |path, event|
      test_calls << [path, event]
    end

    thread = Thread.new do
      Pakyow.run(env: :test, formation: Pakyow::Runnable::Formation.parse(formation), strategy: :threaded)
    end

    Timeout.timeout(10) do
      until test_calls.count > 0
        FileUtils.touch(File.join(test_path, "test.txt"))
        sleep(0.25)
      end

      sleep(0.25)

      calls.clear

      yield if block_given?

      if expected > 0
        until calls.count >= expected
          sleep(0.25)
        end
      else
        sleep(1)
      end
    end

    thread.kill; thread.join
  end

  let(:path) {
    File.expand_path("../tmp", __FILE__)
  }

  let(:test_path) {
    File.expand_path("../tmp-test", __FILE__)
  }

  let(:changed_path) {
    File.join(path, "foo.txt")
  }

  let(:ignored_path) {
    File.join(path, "bar.txt")
  }

  let(:calls) {
    []
  }

  let(:changed_callbacks) {
    Pakyow.changed do |path, event|
      calls << [path, event]
    end
  }

  before do
    Pakyow.watch(path)
    Pakyow.watch(test_path)
    Pakyow.ignore(ignored_path)
    changed_callbacks
    FileUtils.mkdir_p(path)
    FileUtils.mkdir_p(test_path)
  end

  after do
    FileUtils.rm_r(path)
  end

  it "calls the callback when a watched file changes" do
    run(1) do
      FileUtils.touch(changed_path)
    end

    expect(calls).to include([changed_path, :added])
  end

  it "does not call the callback when an ignored file changes" do
    run do
      FileUtils.touch(ignored_path)
    end

    expect(calls.count).to eq(0)
  end

  describe "defining a callback with a matcher" do
    let(:changed_callbacks) {
      Pakyow.changed /baz\.txt/ do |path, event|
        calls << [path, event]
      end
    }

    let(:matched_path) {
      File.join(path, "baz.txt")
    }

    let(:unmatched_path) {
      File.join(path, "foo.txt")
    }

    it "calls the callback for matched changes" do
      run(1) do
        FileUtils.touch(matched_path)
      end

      expect(calls).to include([matched_path, :added])
    end

    it "does not call the callback for unmatched changes" do
      run do
        FileUtils.touch(unmatched_path)
      end

      expect(calls.count).to eq(0)
    end
  end

  describe "defining a callback for a snapshot" do
    let(:changed_callbacks) {
      Pakyow.changed snapshot: true do |snapshot|
        calls << snapshot
      end
    }

    let(:matched_path_1) {
      File.join(path, "foo.txt")
    }

    let(:matched_path_2) {
      File.join(path, "bar.txt")
    }

    it "calls the callback with a snapshot" do
      run(1) do
        FileUtils.touch(matched_path_1)
        FileUtils.touch(matched_path_2)
      end

      expect(calls[0]).to be_instance_of(Pakyow::Filewatcher::Diff)
    end
  end
end
