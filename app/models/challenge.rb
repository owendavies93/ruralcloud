class Challenge < ActiveRecord::Base
  validates :description, :difficulty, :owner, :spec, :presence => true
  validate :not_in_past, :later_than_start
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime

  has_and_belongs_to_many :users

 def not_in_past
  if !starttime.blank? and starttime < DateTime.now
    errors.add(:starttime, "Start time can't be in the past")
  end
  if !endtime.blank? and endtime < DateTime.now
    errors.add(:endtime, "End time can't be in the past")
  end
end

def later_than_start
  if !starttime.blank? and !endtime.blank? and starttime >= endtime
    errors.add(:endtime, "Start time can't be after or equal to end time")
  end
end

end
