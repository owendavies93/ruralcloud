class AddLogToChallenges < ActiveRecord::Migration
  def self.up
    add_column :challenges, :log, :string, :default => ""
  end

  def self.down
    remove_column :challenges, :log
  end
end
