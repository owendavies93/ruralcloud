require 'amqp'
require 'beefcake'

module Rabbitq
  class RuralTest
    include Beefcake::Message

    required :input, :string, 1
    repeated :output, :string, 2
  end

  class RuralMessage
    include Beefcake::Message

    module JobType
      Eval = 0
      Compile = 1
      Test = 2
    end

    required :type, JobType, 1
    required :code, :string, 2
    required :filename, :string, 3
    repeated :tests, RuralTest, 4
  end

  class RuralTestOutcome
    include Beefcake::Message

    required :passed, :boolean, 1
    required :actual, :string, 2
    required :expected, :string, 3
  end

  class RuralTestResponse
    include Beefcake::Message

    repeated :tests, RuralTestOutcome, 1
  end

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
        puts user_id

        serialisedMessage = RuralMessage.new
        serialisedMessage.type = type
        serialisedMessage.code = message
        serialisedMessage.filename = file

        m = ""
        serialisedMessage.encode(m)

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

            puts "hello"

            timer = EventMachine::PeriodicTimer.new(0.1) do
              if result = AdmitEventMachine::requests_list[corr_id]
                puts "waited for " + corr_id

                block.call(result, challenge)
                Pusher['private-' + user_id].trigger('remote-message', {:result => result})
                timer.cancel
              end
            end
          }
        else
         puts "Ohno"
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
