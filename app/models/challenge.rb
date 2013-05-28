class Challenge < ActiveRecord::Base
  validates :description, :owner, :spec, :presence => true
  validates :difficulty, :inclusion => {:in => 0..10, :message => "isn't between 1 and 10"}
  validate :not_in_past, :later_than_start, :not_invalid
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime, :log

  has_many :entries
  has_many :users, :through => :entries

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

  def not_invalid
    if starttime == nil
      errors.add(:starttime, "Start time supplied was not valid")
    end
    if endtime == nil
      errors.add(:endtime, "End time supplied was not valid")
    end
  end

end
