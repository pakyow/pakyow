require "pakyow/logger/timekeeper"

RSpec.describe Pakyow::Logger::Timekeeper do
  let :timekeeper do
    Pakyow::Logger::Timekeeper
  end

  describe "::format_elapsed_time" do
    after do
      timekeeper.format_elapsed_time(time)
    end

    context "when time is greater than 60 seconds" do
      let :time do
        61
      end

      it "formats in minutes" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_minutes).with(time)
      end
    end

    context "when time is equal to 60 seconds" do
      let :time do
        60
      end

      it "formats in minutes" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_minutes).with(time)
      end
    end

    context "when time is greater than 1 second" do
      let :time do
        2
      end

      it "formats in seconds" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_seconds).with(time)
      end
    end

    context "when time is equal to 1 second" do
      let :time do
        1
      end

      it "formats in seconds" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_seconds).with(time)
      end
    end

    context "when time is greater than 1 millisecond" do
      let :time do
        0.01
      end

      it "formats in milliseconds" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_milliseconds).with(time)
      end
    end

    context "when time is equal to 1 millisecond" do
      let :time do
        0.001
      end

      it "formats in milliseconds" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_milliseconds).with(time)
      end
    end

    context "when time is less than 1 millisecond" do
      let :time do
        0.0001
      end

      it "formats in microseconds" do
        expect(Pakyow::Logger::Timekeeper).to receive(:format_elapsed_time_in_microseconds).with(time)
      end
    end
  end

  describe "::format_elapsed_time_in_minutes" do
    it "formats seconds as minutes" do
      expect(timekeeper.format_elapsed_time_in_minutes(60)).to eq ("1.00m ")
    end
  end

  describe "::format_elapsed_time_in_seconds" do
    it "formats seconds as seconds" do
      expect(timekeeper.format_elapsed_time_in_seconds(1)).to eq ("1.00s ")
    end
  end

  describe "::format_elapsed_time_in_milliseconds" do
    it "formats seconds as milliseconds" do
      expect(timekeeper.format_elapsed_time_in_milliseconds(0.01)).to eq ("10.00ms")
    end
  end

  describe "::format_elapsed_time_in_microseconds" do
    it "formats seconds as microseconds" do
      expect(timekeeper.format_elapsed_time_in_microseconds(0.00001)).to eq ("10.00μs")
    end
  end

  describe "::round_elapsed_time" do
    it "rounds to two decimals" do
      expect(timekeeper.round_elapsed_time(1)).to eq("1.00")
    end
  end
end
