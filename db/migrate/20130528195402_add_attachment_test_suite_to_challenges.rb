class AddAttachmentTestSuiteToChallenges < ActiveRecord::Migration
  def self.up
    add_attachment :challenges, :test_suite
  end

  def self.down
    remove_attachment :challenges, :test_suite
  end
end
