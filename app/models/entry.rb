class Entry < ActiveRecord::Base
  attr_accessible :challenge_id, :compilations, :length, :lines, :user_id

  belongs_to :user
  belongs_to :challenge
end
