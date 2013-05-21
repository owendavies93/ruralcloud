class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
      t.text :description
      t.integer :difficulty
      t.text :spec
      t.datetime :starttime
      t.datetime :endtime
      t.string :owner

      t.timestamps
    end
  end
end
