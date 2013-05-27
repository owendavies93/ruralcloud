class AddLogToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :log, :string
  end
end
