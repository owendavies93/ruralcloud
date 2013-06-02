class CreateTests < ActiveRecord::Migration
  def change
    create_table :tests do |t|
      t.integer :challenge_id
      t.text :input

      t.timestamps
    end
  end
end
