require 'amqp'
require 'rabbitq/rural.pb'

module Rabbitq

  class Client
    attr_accessor :thread

    def self.publish(message, block, type, code, challenge, user)
      new.publish(message, block, type, code, challenge, user)
    end

    def publish(message, block, type, code, challenge, user)
      begin
        puts message
        puts code

        serialisedMessage = RuralJob.new

        if type == 0
          serialisedMessage.jobType = RuralJob::JobType::EVAL
          serialisedMessage.expr = message
        elsif type == 1
          serialisedMessage.jobType = RuralJob::JobType::COMPILE
        elsif type == 2
          serialisedMessage.jobType = RuralJob::JobType::TEST
        end

        serialisedMessage.code = code

        if type == 2
          # create some data structures containing tests
          tests = ChallengeTest.where(:challenge_id => challenge);
          tests.each do |test|
            rtest = RuralTest.new
            rtest.input = test.input
            test.outputs.each do |output|
              rtest.output << output.test_output
            end
            serialisedMessage.test << rtest
          end
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
                  Pusher['private-' + user.to_s].trigger('remote-message', {:result => result})
                else
                  entry = Entry.where(:challenge_id => challenge, :user_id => user).first

                  passed_count = 0

                  response = RuralTestResponse.new
                  response.parse_from_string result

                  response.outcome.each do |output|
                    outcome = TestOutcome.new do |o|
                      o.entry_id = entry.id
                      o.passed   = output.passed
                      o.expected = output.expectedOutput
                      o.recieved = output.userOutput

                      if output.passed
                        passed_count += 1
                      end
                    end
                    outcome.save
                  end

                  entry.update_attribute("test_score", passed_count)
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
