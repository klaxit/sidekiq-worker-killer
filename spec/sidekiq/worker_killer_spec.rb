require "spec_helper"

describe Sidekiq::WorkerKiller do
  let(:sidekiq_process_set) { instance_double(Sidekiq::ProcessSet) }
  let(:sidekiq_process) { instance_double(Sidekiq::Process) }

  before do
    allow(subject).to receive(:warn) # silence "warn" logs
    allow(subject).to receive(:sleep) # reduces tests running time
    allow(Sidekiq::ProcessSet).to receive(:new) { sidekiq_process_set }
    allow(sidekiq_process_set).to receive(:find) { sidekiq_process }
    allow(sidekiq_process).to receive(:quiet!)
    allow(sidekiq_process).to receive(:stop!)
    allow(sidekiq_process).to receive(:stopping?)
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
        allow(job).to receive(:[]).with('jid').and_return(4)
        allow(job).to receive(:[]).with('args').and_return(5)
      end

      it "should request shutdown" do
        expect(subject).to receive(:request_shutdown)
        subject.call(worker, job, queue){}
      end

      it "should call garbage collect" do
        allow(subject).to receive(:request_shutdown)
        expect(GC).to receive(:start).with(full_mark: true, immediate_sweep: true)
        subject.call(worker, job, queue){}
      end

      context "and skip_shutdown_if is given" do
        subject{ described_class.new(max_rss: 2, skip_shutdown_if: skip_shutdown_proc) }

        context "and skip_shutdown_if is a proc" do
          let(:skip_shutdown_proc) { proc { |worker| true } }
          it "should NOT request shutdown" do
            expect(subject).not_to receive(:request_shutdown)
            subject.call(worker, job, queue){}
          end
        end

        context "and skip_shutdown_if is a lambda" do
          let(:skip_shutdown_proc) { ->(worker, job, queue) { true } }
          it "should NOT request shutdown" do
            expect(subject).not_to receive(:request_shutdown)
            subject.call(worker, job, queue){}
          end
        end

        context "and skip_shutdown_if returns false" do
          let(:skip_shutdown_proc) { proc { |worker, job, queue| false } }
          it "should still request shutdown" do
            expect(subject).to receive(:request_shutdown)
            subject.call(worker, job, queue){}
          end
        end

        context "and skip_shutdown_if returns nil" do
          let(:skip_shutdown_proc) { proc { |worker, job, queue| nil } }
          it "should still request shutdown" do
            expect(subject).to receive(:request_shutdown)
            subject.call(worker, job, queue){}
          end
        end
      end

      context "when gc is false" do
        subject{ described_class.new(max_rss: 2, gc: false) }
        it "should not call garbage collect" do
          allow(subject).to receive(:request_shutdown)
          expect(GC).not_to receive(:start)
          subject.call(worker, job, queue){}
        end
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
    context "grace time is default" do
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

    context "grace time is 5 seconds" do
      subject{ described_class.new(max_rss: 2, grace_time: 5.0, shutdown_wait: 0) }
      it "should wait the specified grace time before calling shutdown" do
        # there are busy jobs that will not terminate within the grace time
        allow(subject).to receive(:no_jobs_on_quiet_processes?).and_return(false)

        shutdown_request_time     = nil
        shutdown_time             = nil

        # replace the original #request_shutdown to track
        # when the shutdown is requested
        original_request_shutdown = subject.method(:request_shutdown)
        allow(subject).to receive(:request_shutdown) do
          shutdown_request_time= Time.now
          original_request_shutdown.call
        end

        # track when the process has been required to stop
        expect(sidekiq_process).to receive(:stop!) do |*args|
          shutdown_time = Time.now
        end

        allow(Process).to receive(:kill)
        allow(Process).to receive(:pid).and_return(99)

        subject.send(:request_shutdown).join

        elapsed_time = shutdown_time - shutdown_request_time

        # the elapsed time between shutdown request and the actual
        # shutdown signal should be greater than the specified grace_time
        expect(elapsed_time).to be >= 5.0
      end
    end

    context "grace time is Float::INFINITY" do
      subject{ described_class.new(max_rss: 2, grace_time: Float::INFINITY, shutdown_wait: 0) }
      it "call signal only on jobs" do
        allow(subject).to receive(:jobs_finished?).and_return(true)
        allow(Process).to receive(:pid).and_return(99)
        expect(sidekiq_process).to receive(:quiet!)
        expect(sidekiq_process).to receive(:stop!)
        expect(Process).to receive(:kill).with('SIGKILL', 99)

        subject.send(:request_shutdown).join
      end
    end
  end
end
