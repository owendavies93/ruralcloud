class RemoveFileHashFromEntries < ActiveRecord::Migration
  def up
    remove_column :entries, :file_hash
  end

  def down
    add_column :entries, :file_hash, :string
  end
end
