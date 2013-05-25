require 'rabbitq/client'

class HomeController < ApplicationController
  def index
  end

  def send_message(n)
    Rabbitq::Client::publish("4+3", self)
  end
  helper_method :send_message

  def call(result)
    puts result
  end
end
