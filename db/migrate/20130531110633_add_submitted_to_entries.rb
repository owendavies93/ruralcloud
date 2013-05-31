class AddSubmittedToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :submitted, :boolean, :default => false
  end
end
