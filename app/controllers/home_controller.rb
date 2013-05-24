require 'amqp'

class HomeController < ApplicationController
  def index
    EventMachine.run do
        AMQP.connect(:host => 'ruralcloud.charlie.ht', :user => "ruralcloud", :pass => "i64MMyFtCPPD") do |connection|
            puts "Connected!"

            channel = AMQP::Channel.new(connection)

            callback_queue = channel.queue("", :auto_delete => true, :durable => true, :exclusive => true)
            puts callback_queue.name
            puts callback_queue

            requests = Hash.new

            callback_queue.subscribe do |header, body|
                corr_id = header.correlation_id
                unless requests[corr_id]
                    requests[corr_id] = body
                end
            end

            corr_id = rand(10_000_000).to_s
            puts corr_id

            requests[corr_id] = nil

            callback_queue.append_callback(:declare) do
                channel.default_exchange.publish("5+3*7", :routing_key => "rural_jobs", :reply_to => callback_queue.name, :correlation_id => corr_id, :persistent => true)

                EventMachine.add_periodic_timer(0.1) do
                    puts "Checking for result"
                    if result = requests[corr_id]
                        puts result
                        EventMachine.stop
                    end
                end
            end
        end
    end
  end
end
