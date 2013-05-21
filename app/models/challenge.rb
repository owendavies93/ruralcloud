class Challenge < ActiveRecord::Base
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime
end
