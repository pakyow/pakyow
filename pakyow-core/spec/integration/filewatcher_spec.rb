require "fileutils"
require "pakyow/filewatcher"

RSpec.describe "using the filewatcher" do
  let(:path) {
    File.expand_path("../tmp", __FILE__)
  }

  let(:test_path) {
    File.expand_path("../tmp-test", __FILE__)
  }

  let(:filewatcher) {
    Pakyow::Filewatcher.new
  }

  let(:calls) {
    []
  }

  before do
    FileUtils.mkdir_p(path)
    FileUtils.mkdir_p(test_path)
  end

  after do
    FileUtils.rm_r(path)
    FileUtils.rm_r(test_path)
  end

  def perform(expected = 0)
    test_calls = []

    filewatcher.watch(test_path)
    filewatcher.callback do |path, event|
      test_calls << [path, event]
    end

    thread = Thread.new do
      filewatcher.perform
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

    filewatcher.stop
    sleep 0.25
    thread.kill; thread.join
  end

  describe "watching a pattern" do
    let(:pattern) {
      File.join(path, "**", "*.txt")
    }

    let(:matching_path) {
      File.join(path, "foo.txt")
    }

    let(:unmatching_path) {
      File.join(path, "foo.rb")
    }

    before do
      filewatcher.watch(pattern)
    end

    context "one callback is defined" do
      before do
        filewatcher.callback do |path, event|
          calls << [path, event]
        end
      end

      context "nothing changes" do
        it "does not call the callback" do
          perform(0)

          expect(calls).to be_empty
        end
      end

      context "file matching the pattern is added" do
        it "calls the callback with expected arguments" do
          perform(1) do
            FileUtils.touch(matching_path)
          end

          expect(calls).to eq([[matching_path, :added]])
        end
      end

      context "file matching the pattern is changed" do
        before do
          FileUtils.touch(matching_path)
        end

        it "calls the callback with expected arguments" do
          perform do
            FileUtils.touch(matching_path)
          end

          expect(calls).to eq([[matching_path, :changed]])
        end
      end

      context "file matching the pattern is removed" do
        before do
          FileUtils.touch(matching_path)
        end

        it "calls the callback with expected arguments" do
          perform do
            FileUtils.rm(matching_path)
          end

          expect(calls).to eq([[matching_path, :removed]])
        end
      end

      context "file not matching the pattern is added" do
        it "does not call the callback" do
          perform do
            FileUtils.touch(unmatching_path)
          end

          expect(calls).to be_empty
        end
      end

      context "file not matching the pattern is changed" do
        before do
          FileUtils.touch(unmatching_path)
        end

        it "does not call the callback" do
          perform do
            FileUtils.touch(unmatching_path)
          end

          expect(calls).to be_empty
        end
      end

      context "file not matching the pattern is removed" do
        before do
          FileUtils.touch(unmatching_path)
        end

        it "does not call the callback" do
          perform do
            FileUtils.rm(unmatching_path)
          end

          expect(calls).to be_empty
        end
      end
    end

    context "multiple callbacks are defined" do
      before do
        filewatcher.callback do |path, event|
          calls << [path, event, :cb1]
        end

        filewatcher.callback do |path, event|
          calls << [path, event, :cb2]
        end
      end

      context "file is added" do
        it "calls each callback with expected arguments" do
          perform do
            FileUtils.touch(matching_path)
          end

          expect(calls).to eq([
            [matching_path, :added, :cb1],
            [matching_path, :added, :cb2]
          ])
        end
      end
    end

    context "no callbacks are defined" do
      context "file is added" do
        it "doesn't fail" do
          expect {
            perform do
              FileUtils.touch(matching_path)
            end
          }.not_to raise_error
        end
      end
    end
  end

  describe "watching a folder" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path) {
      File.join(path, "foo.txt")
    }

    context "file is added" do
      it "calls the callback with expected arguments" do
        perform do
          FileUtils.touch(matching_path)
        end

        expect(calls).to eq([[matching_path, :added]])
      end
    end

    context "file is changed" do
      before do
        FileUtils.touch(matching_path)
      end

      it "calls the callback with expected arguments" do
        perform do
          FileUtils.touch(matching_path)
        end

        expect(calls).to eq([[matching_path, :changed]])
      end
    end

    context "file is removed" do
      before do
        FileUtils.touch(matching_path)
      end

      it "calls the callback with expected arguments" do
        perform do
          FileUtils.rm(matching_path)
        end

        expect(calls).to eq([[matching_path, :removed]])
      end
    end

    context "file is added in a sub-folder" do
      before do
        FileUtils.mkdir_p(sub_path)
      end

      let(:sub_path) {
        File.join(path, "sub")
      }

      it "call the callback for the sub-folder, not the file" do
        perform do
          FileUtils.touch(File.join(sub_path, "foo.txt"))
        end

        expect(calls).to eq([[sub_path, :changed]])
      end
    end
  end

  describe "watching a file" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      File.join(path, "foo.txt")
    }

    let(:matching_path) {
      pattern
    }

    context "file is added" do
      it "calls the callback with expected arguments" do
        perform do
          FileUtils.touch(matching_path)
        end

        expect(calls).to eq([[matching_path, :added]])
      end
    end

    context "file is changed" do
      before do
        FileUtils.touch(matching_path)
      end

      it "calls the callback with expected arguments" do
        perform do
          FileUtils.touch(matching_path)
        end

        expect(calls).to eq([[matching_path, :changed]])
      end
    end

    context "file is removed" do
      before do
        FileUtils.touch(matching_path)
      end

      it "calls the callback with expected arguments" do
        perform do
          FileUtils.rm(matching_path)
        end

        expect(calls).to eq([[matching_path, :removed]])
      end
    end
  end

  describe "defining a callback with a string matcher" do
    before do
      filewatcher.callback(matcher) do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:matcher) {
      matching_path
    }

    let(:matching_path) {
      File.join(path, "foo.txt")
    }

    let(:unmatching_path) {
      File.join(path, "bar.txt")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "calls the callback for changes that match" do
      perform do
        FileUtils.touch(matching_path)
      end

      expect(calls).to eq([[matching_path, :added]])
    end

    it "does not call the callback for changes that don't match" do
      perform do
        FileUtils.touch(unmatching_path)
      end

      expect(calls).to be_empty
    end
  end

  describe "defining a callback with a regexp matcher" do
    before do
      filewatcher.callback(matcher) do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:matcher) {
      /foo/
    }

    let(:matching_path) {
      File.join(path, "foo.txt")
    }

    let(:unmatching_path) {
      File.join(path, "bar.txt")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "calls the callback for changes that match" do
      perform do
        FileUtils.touch(matching_path)
      end

      expect(calls).to eq([[matching_path, :added]])
    end

    it "does not call the callback for changes that don't match" do
      perform do
        FileUtils.touch(unmatching_path)
      end

      expect(calls).to be_empty
    end
  end

  describe "ignoring a pattern" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.ignore(File.join(ignored_path, "/**/*"))
      filewatcher.watch(pattern)

      FileUtils.mkdir(File.join(ignored_path))
    end

    let(:ignored_path) {
      File.join(path, "ignored")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "only calls the callback for changes that are not ignored" do
      perform do
        FileUtils.touch(File.join(ignored_path, "foo.txt"))
        FileUtils.mkdir(File.join(ignored_path, "bar"))
        FileUtils.touch(File.join(ignored_path, "bar/foo.txt"))
      end

      expect(calls).to eq([[ignored_path, :changed]])
    end
  end

  describe "ignoring a file" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.ignore(File.join(ignored_path))
      filewatcher.watch(pattern)
    end

    let(:ignored_path) {
      File.join(path, "foo.txt")
    }

    let(:added_path) {
      File.join(path, "bar.txt")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "only calls the callback for changes that are not ignored" do
      perform do
        FileUtils.touch(ignored_path)
        FileUtils.touch(added_path)
      end

      expect(calls).to eq([[added_path, :added]])
    end
  end

  describe "ignoring a directory" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.ignore(File.join(ignored_path))
      filewatcher.watch(pattern)
    end

    let(:ignored_path) {
      File.join(path)
    }

    let(:added_path) {
      File.join(path, "foo.txt")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "only calls the callback for changes that are not ignored" do
      perform do
        FileUtils.touch(ignored_path)
        FileUtils.touch(added_path)
      end

      expect(calls).to eq([[added_path, :added]])
    end
  end

  describe "ignoring a regexp" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.ignore(/foo/)
      filewatcher.watch(pattern)
    end

    let(:ignored_path) {
      File.join(path, "foo.txt")
    }

    let(:added_path) {
      File.join(path, "bar.txt")
    }

    let(:pattern) {
      File.join(path, "**", "*")
    }

    it "only calls the callback for changes that are not ignored" do
      perform do
        FileUtils.touch(ignored_path)
        FileUtils.touch(added_path)
      end

      expect(calls).to eq([[added_path, :added]])
    end
  end

  describe "adding a watch after the watcher is running" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end
    end

    let(:pattern) {
      path
    }

    let(:matching_path) {
      File.join(path, "foo.txt")
    }

    it "watches the file correctly" do
      perform do |task|
        filewatcher.watch(pattern)
        # We still have to sleep to give the next tick a chance to complete.
        sleep(filewatcher.interval)
        FileUtils.touch(matching_path)
      end

      expect(calls).to eq([[matching_path, :added]])
    end
  end

  describe "multiple changed files" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path_1) {
      File.join(path, "foo.txt")
    }

    let(:matching_path_2) {
      File.join(path, "bar.txt")
    }

    let(:matching_path_3) {
      File.join(path, "baz.txt")
    }

    it "calls the callback for each changed file" do
      perform do
        FileUtils.touch(matching_path_1)
        FileUtils.touch(matching_path_2)
        FileUtils.touch(matching_path_3)
      end

      expect(calls.count).to eq(3)
      expect(calls).to include([matching_path_1, :added])
      expect(calls).to include([matching_path_2, :added])
      expect(calls).to include([matching_path_3, :added])
    end
  end

  describe "multiple files with only one change" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path_1) {
      File.join(path, "foo.txt")
    }

    let(:matching_path_2) {
      File.join(path, "bar.txt")
    }

    let(:matching_path_3) {
      File.join(path, "baz.txt")
    }

    it "calls the callback for each changed file" do
      FileUtils.touch(matching_path_1)
      FileUtils.touch(matching_path_3)

      perform do
        FileUtils.touch(matching_path_2)
      end

      expect(calls.count).to eq(1)
      expect(calls).to include([matching_path_2, :added])
    end
  end

  describe "batching changes in a snapshot" do
    before do
      filewatcher.callback(snapshot: true) do |snapshot|
        calls << snapshot
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path_1) {
      File.join(path, "foo.txt")
    }

    let(:matching_path_2) {
      File.join(path, "bar.txt")
    }

    let(:matching_path_3) {
      File.join(path, "baz.txt")
    }

    it "calls the callback once with the snapshot" do
      perform(1) do
        FileUtils.touch(matching_path_1)
        FileUtils.touch(matching_path_2)
        FileUtils.touch(matching_path_3)
      end

      expect(calls.count).to eq(1)
      expect(calls[0]).to be_instance_of(Pakyow::Filewatcher::Diff)
      expect(calls[0].each_changed_path.to_a).to include(matching_path_1)
      expect(calls[0].each_changed_path.to_a).to include(matching_path_2)
      expect(calls[0].each_changed_path.to_a).to include(matching_path_3)
    end

    context "only one file changes" do
      it "calls the callback once with the correct snapshot" do
        FileUtils.touch(matching_path_1)
        FileUtils.touch(matching_path_3)

        perform(1) do
          FileUtils.touch(matching_path_2)
        end

        expect(calls.count).to eq(1)
        expect(calls[0]).to be_instance_of(Pakyow::Filewatcher::Diff)
        expect(calls[0].each_changed_path.to_a.count).to eq(1)
        expect(calls[0].each_changed_path.to_a).to include(matching_path_2)
      end
    end
  end

  describe "adding a file to a new folder" do
    before do
      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path) {
      File.join(path, "sub", "foo.txt")
    }

    it "calls the callback for the folder" do
      perform do
        FileUtils.mkdir_p(File.dirname(matching_path))
        FileUtils.touch(matching_path)
      end

      expect(calls).to eq([[File.dirname(matching_path), :added]])
    end
  end

  describe "deleting a folder" do
    before do
      FileUtils.mkdir_p(File.dirname(matching_path))
      FileUtils.touch(matching_path)

      filewatcher.callback do |path, event|
        calls << [path, event]
      end

      filewatcher.watch(pattern)
    end

    let(:pattern) {
      path
    }

    let(:matching_path) {
      File.join(path, "sub", "foo.txt")
    }

    it "calls the callback for the folder" do
      perform do
        FileUtils.rm_r(File.dirname(matching_path))
      end

      expect(calls).to eq([[File.dirname(matching_path), :removed]])
    end
  end
end
