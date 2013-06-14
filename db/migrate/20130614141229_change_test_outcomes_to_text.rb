class ChangeTestOutcomesToText < ActiveRecord::Migration
  def up
    change_column :test_outcomes, :recieved, :text
    change_column :test_outcomes, :expected, :text
  end

  def down
    change_column :test_outcomes, :recieved, :string
    change_column :test_outcomes, :recieved, :string
  end
end
