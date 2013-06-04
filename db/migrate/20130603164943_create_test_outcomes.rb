class CreateTestOutcomes < ActiveRecord::Migration
  def change
    create_table :test_outcomes do |t|
      t.integer :entry_id
      t.boolean :passed
      t.string :recieved
      t.string :expected

      t.timestamps
    end
  end
end
