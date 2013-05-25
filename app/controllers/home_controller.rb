require 'rabbitq/client'

class HomeController < ApplicationController
  def index
  end

  def send_message
    Rabbitq::Client::publish(params[:input], self)
    throw :async
  end
  helper_method :send_message

  def call(result)
    request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, result]
  end
end
