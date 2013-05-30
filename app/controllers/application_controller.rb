class ApplicationController < ActionController::Base

  protect_from_forgery

  def get_next_start_time
    now = Time.new
    @next_challenge = Challenge.where('starttime > ?', now.inspect).order("starttime asc").first

    if @next_challenge == nil
      return ""
    end

    diff = (@next_challenge.starttime - now).to_i
    daydiff = diff / 1.day
    hourdiff = diff / 1.hour
    mindiff = diff / 1.minute

    if daydiff > 0
      if daydiff == 1
        return daydiff.to_s + " day"
      else
        return daydiff.to_s + " days"
      end
    elsif hourdiff > 0
      if hourdiff == 1
        return hourdiff.to_s + " hour"
      else
        return hourdiff.to_s + " hours"
      end
    elsif mindiff > 0
      if mindiff == 1
        return mindiff.to_s + " minute"
      else
        return mindiff.to_s + " minutes"
      end
    else
      return " under 1 minute!"
    end
  end
  helper_method :get_next_start_time
end
