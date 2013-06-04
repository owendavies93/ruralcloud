class TestOutcome < ActiveRecord::Base
  attr_accessible :entry_id, :expected, :passed, :recieved
end
