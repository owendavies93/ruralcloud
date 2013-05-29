require "net/http"

module ApplicationHelper
  def gravatar user
    avatar user, 64
  end

  def gravatar_small user
    avatar user, 28
  end

  def avatar user, size
    gravatar_id = Digest::MD5::hexdigest(user.email).downcase
    "http://gravatar.com/avatar/#{gravatar_id}.png?s=#{size}&d=identicon"
  end
end
