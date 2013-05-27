class Entry < ActiveRecord::Base
  attr_accessible :challenge_id, :compilations, :length, :lines, :user_id, :evaluations, :failed_compilations, :failed_evaluations

  belongs_to :user
  belongs_to :challenge
end
