require 'amqp'

module AdmitEventMachine  
  def self.start 
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked && EM.reactor_running?
          EM.stop
        end
        Thread.new { 
          EM.run do
            open_channel
          end 
        }
        die_gracefully_on_signal
      end
    else #Development 
      Thread.abort_on_exception = true
        Thread.new { 
          EM.run do
            if EM.reactor_running?
              queue.subscribe do |header, body|
                corr_id = header.correlation_id
                unless requests_list[corr_id]
                  requests_list[corr_id] = body 
                end 
              end
            end                                                    
          end 
        } unless defined?(Thin)  
    end
  end

  def self.open_channel
    return @channel ||= AMQP::Channel.new(AMQP.connect(self.conf))       
  end  

  def self.conf                    
    connection_settings = {:host => "ruralcloud.charlie.ht", :user => "ruralcloud", :pass => "i64MMyFtCPPD"}                                                         
  end

  def self.queue
    return @callback_queue ||= open_channel.queue("", :exclusive => true, :auto_delete => true, :durable => true)  
  end

  def self.requests_list
    return @requests ||= Hash.new    
  end

  def self.die_gracefully_on_signal
    Signal.trap("INT")  { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end
end

AdmitEventMachine.start
