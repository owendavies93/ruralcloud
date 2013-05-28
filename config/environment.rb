# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Ruralcloud::Application.initialize!

# Custom dt formats for removal of UTC and UK format
Date::DATE_FORMATS[:default] = "%m-%d-%Y"
Time::DATE_FORMATS[:default] = "%m-%d-%Y %H:%M:%S"

ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  :domain         => 'heroku.com',
  :enable_starttls_auto => true
}
