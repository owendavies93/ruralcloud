require "net/http"

module ApplicationHelper
  def gravatar user
    avatar user, 80
  end

  def gravatar_small user
    avatar user, 28
  end

  def avatar user, size
    gravatar_id = Digest::MD5::hexdigest(user.email).downcase
    "https://secure.gravatar.com/avatar/#{gravatar_id}.png?s=#{size}&d=identicon"
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end

  def username_or_email id
    user = User.find(id)

    user.username.blank? ? sanitize(user.email) : user.username
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
  end
end
