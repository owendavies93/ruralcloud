require 'amqp'

module Rabbitq
  class Client
    attr_accessor :thread

    def self.publish message
      new.publish message
    end

    def publish message
      begin
        if EventMachine.reactor_running?
          start_em {
            channel = AMQP::Channel.new($connection)
            corr_id = rand(10_000_000).to_s
            requests[corr_id] = nil

            callback_queue.append_callback(:declare) do
              channel.default_exchange.publish(message, :routing_key => "rural_jobs", :reply_to => callback_queue.name, :correlation_id => corr_id, :persistent => true)

              EventMachine.add_periodic_timer(0.1) do
                if result = AMQP.requests[corr_id]
                  puts result
                  break
                end
              end

            end
          }
          return true
        else
         # Event Machine is not running!
         # requeue?
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
