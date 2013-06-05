class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :session_limitable, :omniauthable, :omniauth_providers => [:github]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :editor_theme, :mapping_preference, :provider, :uid,
                  :bio, :username
  # attr_accessible :title, :body

  has_many :entries
  has_many :challenges, :through => :entries

  def self.find_github(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first

    unless user
      user = User.create(provider: auth.provider,
                         uid: auth.uid,
                         email: auth.info.email,
                         password: Devise.friendly_token[0,20])
    end
    user
  end

  def new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.github_data"] && session["devise.github_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

end
