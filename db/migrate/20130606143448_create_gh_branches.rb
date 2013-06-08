class CreateGhBranches < ActiveRecord::Migration
  def change
    create_table :gh_branches do |t|
      t.string :branch
      t.string :file_hash
      t.integer :entry_id

      t.timestamps
    end
  end
end
