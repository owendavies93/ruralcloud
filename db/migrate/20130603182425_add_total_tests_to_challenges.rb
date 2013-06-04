class AddTotalTestsToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :total_tests, :integer
  end
end
