class Output < ActiveRecord::Base
  attr_accessible :test_id, :test_output

  belongs_to :test
end
