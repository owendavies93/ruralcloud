require 'amqp'
require 'rabbitq/rural.pb'

module Rabbitq

  class Client
    attr_accessor :thread

    def self.publish(message, block, type, file, challenge)
      new.publish(message, block, type, file, challenge)
    end

    def publish(message, block, type, file, challenge)
      begin
        user_id = file.partition('_').last
        file = file + ".hs"
        puts message

        serialisedMessage = RuralJob.new
        if type == 0
          serialisedMessage.jobType = RuralJob::JobType::EVAL
        elsif type == 1
          serialisedMessage.jobType = RuralJob::JobType::COMPILE
        elsif type == 2
          serialisedMessage.jobType = RuralJob::JobType::TEST
        end
        serialisedMessage.exprOrCode = message
        serialisedMessage.filename = file

        if type == 2
          puts "hello!"
          # create some data structures containing tests
          tests = ChallengeTest.where(:challenge_id => challenge);
          tests.each do |test|
            puts test
            rtest = RuralTest.new
            rtest.input = test.input
            test.outputs.each do |output|
              rtest.output << output.test_output
            end
            serialisedMessage.test << rtest
          end
          serialisedMessage.exprOrCode = ""
        end

        m = serialisedMessage.to_s

        corr_id = rand(10_000_000).to_s
        AdmitEventMachine::requests_list[corr_id] = nil

        puts "sending " + corr_id

        if EM.reactor_running?
          EM.next_tick() {
            AdmitEventMachine::open_channel.default_exchange.publish(
              m,
              :routing_key => "rural_jobs",
              :reply_to => AdmitEventMachine::queue.name,
              :correlation_id => corr_id
              )

            timer = EventMachine::PeriodicTimer.new(0.1) do
              if result = AdmitEventMachine::requests_list[corr_id]
                puts "waited for " + corr_id
                if type != 2
                  block.call(result, challenge)
                  Pusher['private-' + user_id].trigger('remote-message', {:result => result})
                else
                  block.test_result(result, challenge, user_id)
                end
                timer.cancel
              end
            end
          }
        else
         puts "Event machine is not running, this is a HUGE issue"
         return false
        end
      rescue Exception => exc
        puts exc
        # Store error / Email
        # Requeue sending e.g Delayed Job
        # Error Example: EventMachine::ConnectionError: unable to resolve server address
      end
    end

  end
end
