require "spec_helper"

describe Sidekiq::WorkerKiller do

  before do
    allow(subject).to receive(:warn) # silence "warn" logs
  end

  describe "#call" do
    let(:worker){ double("worker") }
    let(:job){ double("job") }
    let(:queue){ double("queue") }
    it "should yield" do
      expect { |b|
        subject.call(worker, job, queue, &b)
      }.to yield_with_no_args
    end
    context "when current rss is over max rss" do
      subject{ described_class.new(max_rss: 2) }
      before do
        allow(subject).to receive(:current_rss).and_return(3)
      end
      it "should request shutdown" do
        expect(subject).to receive(:request_shutdown)
        subject.call(worker, job, queue){}
      end
      context "but max rss is 0" do
        subject{ described_class.new(max_rss: 0) }
        it "should not request shutdown" do
          expect(subject).to_not receive(:request_shutdown)
          subject.call(worker, job, queue){}
        end
      end
    end
  end

  describe "#request_shutdown" do
    before { allow(subject).to receive(:shutdown){ sleep 0.01 } }
    it "should call shutdown" do
      expect(subject).to receive(:shutdown)
      subject.send(:request_shutdown).join
    end
    it "should not call shutdown twice when called concurrently" do
      expect(subject).to receive(:shutdown).once
      2.times.map{ subject.send(:request_shutdown) }.each(&:join)
    end
  end

  describe "#quiet_signal" do
    it "should give TSTP if Sidekiq version is > 5.0" do
      stub_const("Sidekiq::VERSION", "5.0")
      expect(subject.send :quiet_signal).to eq "TSTP"
      stub_const("Sidekiq::VERSION", "5.2.1")
      expect(subject.send :quiet_signal).to eq "TSTP"
    end
    it "should give USR1 if Sidekiq version is < 5.0" do
      stub_const("Sidekiq::VERSION", "3.0")
      expect(subject.send :quiet_signal).to eq "USR1"
      stub_const("Sidekiq::VERSION", "4.6.7")
      expect(subject.send :quiet_signal).to eq "USR1"
    end
  end
end
