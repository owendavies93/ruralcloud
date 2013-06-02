class Test < ActiveRecord::Base
  attr_accessible :challenge_id, :input, :outputs_attributes

  belongs_to :challenge
  has_many :outputs, :dependent => :destroy
  accepts_nested_attributes_for :outputs, :reject_if => lambda { |a| a[:test_output].blank? }, :allow_destroy => true
end
