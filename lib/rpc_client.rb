require 'singleton'

class RpcClient
  include Singleton

  def initialize
    subscribe_to_callback_queue
  end

  def connection
    @connection ||= AMQP.connect(:host => "ruralcloud.charlie.ht", :user => "ruralcloud", :pass => "i64MMyFtCPPD")
  end

  def channel
    @channel ||= AMQP::Channel.new(self.connection)
  end

  def callback_queue
    @callback_queue ||= self.channel.queue("", :exclusive => true, :auto_delete => true, :durable => true)
  end

  def requests
    @requests ||= Hash.new
  end

  def call(n, &block)
    corr_id = rand(10_000_000).to_s
    self.requests[corr_id] = nil
    puts "waiting outside"
    self.callback_queue.append_callback(:declare) do
      puts "now inside"
      self.channel.default_exchange.publish(n.to_s, :routing_key => "rural_jobs", :reply_to => self.callback_queue.name, :correlation_id => corr_id)
      EM.add_periodic_timer(0.1) do
        puts corr_id
        # p self.requests
        if result = self.requests[corr_id]
          block.call(result)
          puts "sent back " + corr_id
          EM.stop
        end
      end
      puts "got here with " + corr_id
    end
  end

  private
  def subscribe_to_callback_queue
    self.callback_queue.subscribe do |header, body|
      corr_id = header.correlation_id
      unless self.requests[corr_id]
        self.requests[corr_id] = body
      end
    end
  end
end
