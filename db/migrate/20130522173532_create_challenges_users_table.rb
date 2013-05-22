class CreateChallengesUsersTable < ActiveRecord::Migration
  def self.up
    create_table :challenges_users, :id => false do |t|
        t.integer :challenge_id
        t.integer :user_id
    end
  end

  def self.down
    drop_table :challenges_users
  end
end
