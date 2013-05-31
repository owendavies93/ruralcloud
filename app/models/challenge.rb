class Challenge < ActiveRecord::Base
  validates :description, :owner, :spec, :presence => true
  validates :difficulty, :inclusion => {:in => 0..10, :message => "isn't between 1 and 10"}
  validate :not_in_past, :later_than_start, :not_invalid, :valid_test_suite
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime, :log, :test_suite

  has_attached_file :test_suite
  validates_attachment :test_suite, :presence => true, :content_type => { :content_type => "text/plain" }
  before_save :valid_test_suite

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

  def valid_test_suite
    cur_test_line = 0
    if test_suite.queued_for_write[:original] != nil
      File.open(test_suite.queued_for_write[:original].path) do |f|
        f.each_with_index do |line, index|
          if index == 0
            if line[0] != '>'
              errors.add(:test_suite, "Test suite must start with test")
            end
          else
            if line[0] == '>' && (index == cur_test_line + 1 || f.eof?)
              errors.add(:test_suite, "All tests must have at least one possible output")
            elsif line[0] == '>'
              cur_test_line = index
            end
          end
        end
      end
    else
      errors.add(:test_suite, "Must submit test suite file")
    end
  end

end
