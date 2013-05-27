require 'amqp'
require 'beefcake'

module Rabbitq
  class RuralMessage
    include Beefcake::Message
    required :code, :string, 1

    required :filename, :string, 2
  end

  class Client
    attr_accessor :thread

    def self.publish(message, block, file="")
      new.publish message, block, file
    end

    def publish(message, block, file="")
      begin
        serialisedMessage = RuralMessage.new
        serialisedMessage.code = message
        serialisedMessage.filename = file

        m = ""
        serialisedMessage.encode(m)

        corr_id = rand(10_000_000).to_s
        AdmitEventMachine::requests_list[corr_id] = nil

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
                block.call(result)
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
