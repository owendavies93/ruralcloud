class Challenge < ActiveRecord::Base
  attr_accessible :description, :difficulty, :endtime, :owner, :spec, :starttime

  has_and_belongs_to_many :users
end
