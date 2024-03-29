class Entry < ActiveRecord::Base
  attr_accessible :challenge_id, :compilations, :length, :lines, :user_id, :evaluations, :failed_compilations, :failed_evaluations, :last_code

  belongs_to :user
  belongs_to :challenge
  has_many :test_outcomes
  has_many :gh_branches
end
