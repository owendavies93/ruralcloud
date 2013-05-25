require 'rabbitq/client'

class HomeController < ApplicationController
  def index
  end

  def send_message
    Rabbitq::Client::publish(params[:input], self)
    render :partial => 'message', :content_type => 'text/html'
  end
  helper_method :send_message

  def call(result)
    puts result
  end
end
