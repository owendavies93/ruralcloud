class CreateOutputs < ActiveRecord::Migration
  def change
    create_table :outputs do |t|
      t.integer :challenge_test_id
      t.string :test_output

      t.timestamps
    end
  end
end
