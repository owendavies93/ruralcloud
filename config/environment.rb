# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Ruralcloud::Application.initialize!

# Custom dt formats for removal of UTC and UK format
Date::DATE_FORMATS[:default] = "%m-%d-%Y"
Time::DATE_FORMATS[:default] = "%m-%d-%Y %H:%M:%S"
