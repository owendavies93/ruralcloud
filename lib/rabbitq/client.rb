require 'amqp'
require 'beefcake'

module Rabbitq
  class RuralMessage
    include Beefcake::Message
    required :compile, :int32, 1
    required :code, :string, 2
    required :filename, :string, 3
  end

  class Client
    attr_accessor :thread

    def self.publish(message, block, compile, file, challenge)
      new.publish(message, block, compile, file, challenge)
    end

    def publish(message, block, compile, file, challenge)
      begin
        if compile == 1
          message = "module " + file + " where\n" + message
        end

        file = file + ".hs"
        puts message

        serialisedMessage = RuralMessage.new
        serialisedMessage.compile = compile
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

              timer = EventMachine::PeriodicTimer.new(0.1) do
              if result = AdmitEventMachine::requests_list[corr_id]
                puts "waiting for " + corr_id
                block.call(result, challenge)
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
