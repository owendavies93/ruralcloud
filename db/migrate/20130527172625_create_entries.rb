class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.integer :challenge_id
      t.integer :user_id
      t.integer :compilations
      t.integer :length
      t.integer :lines

      t.timestamps
    end
  end
end
