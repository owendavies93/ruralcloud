require 'rpc_client'

class HomeController < ApplicationController
  def index
    # EM.run do
    #   puts " [x] Requesting 3*15"
    #   RpcClient.instance.call("3*15") do |response|
    #     puts " [.] Got #{response}"
    #   end

    #   RpcClient.instance.call("3*15") do |response|
    #     puts " [.] Got #{response}"
    #   end
    # end
    # puts "heelo"
  end

  def send_message(n, &block)
    EM.run do
      connection = AMQP.connect(:host => "ruralcloud.charlie.ht", :user => "ruralcloud", :pass => "i64MMyFtCPPD")

      channel = AMQP::Channel.new(connection)

      callback_queue = channel.queue("", :exclusive => true, :auto_delete => true, :durable => true)
      requests = Hash.new

      callback_queue.subscribe do |header, body|
        corr_id = header.correlation_id
        unless  requests[corr_id]
          requests[corr_id] = body
        end
      end

      corr_id = rand(10_000_000).to_s
      requests[corr_id] = nil

      callback_queue.append_callback(:declare) do
        channel.default_exchange.publish(n.to_s, :routing_key => "rural_jobs", :reply_to => callback_queue.name, :correlation_id => corr_id)
        EM.add_periodic_timer(0.1) do
          if result = requests[corr_id]
            puts result
            EM.stop
          end
        end
      end
    end
  end
  helper_method :send_message

end
