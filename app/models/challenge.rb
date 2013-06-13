class Challenge < ActiveRecord::Base
  validates :description, :owner, :spec, :presence => true
  validates :difficulty, :inclusion => {:in => 0..10, :message => "isn't between 1 and 10"}
  validate :not_in_past, :later_than_start, :not_invalid
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime, :log, :challenge_tests_attributes, :test_score, :total_tests

  has_many :entries, :dependent => :destroy
  has_many :users, :through => :entries
  has_many :challenge_tests, :dependent => :destroy
  accepts_nested_attributes_for :challenge_tests, :reject_if => lambda { |a| a[:input].blank? }

  validates_presence_of :challenge_tests

  def not_in_past
    if !starttime.blank? and starttime < DateTime.now
      errors.add(:starttime, "can't be in the past")
    end
    if !endtime.blank? and endtime < DateTime.now
      errors.add(:endtime, "can't be in the past")
    end
  end

  def later_than_start
    if !starttime.blank? and !endtime.blank? and starttime >= endtime
      errors.add(:endtime, "can't be after or equal to end time")
    end
  end

  def not_invalid
    if starttime == nil
      errors.add(:starttime, "supplied was not valid")
    end
    if endtime == nil
      errors.add(:endtime, "supplied was not valid")
    end
  end
end
