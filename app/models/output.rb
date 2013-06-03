class Output < ActiveRecord::Base
  attr_accessible :challenge_test_id, :test_output

  belongs_to :challenge_test
end
