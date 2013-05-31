class AddTestSuiteToChallenges < ActiveRecord::Migration
  def change
    add_column :challenges, :test_suite, :text
  end
end
