class AddFileHashToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :file_hash, :string
  end
end
