class AddMaxDifficultyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_difficulty, :integer
  end
end
