require "spec_helper"

describe Sidekiq::WorkerKiller do
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
      it "should perform kill" do
        expect(subject).to receive(:perform_kill).with(worker)
        subject.call(worker, job, queue){}
      end
      context "but max rss is 0" do
        subject{ described_class.new(max_rss: 0) }
        it "should not perform kill" do
          expect(subject).to_not receive(:perform_kill).with(worker)
          subject.call(worker, job, queue){}
        end
      end
    end

  end
end
