class AddLastCodeToEntry < ActiveRecord::Migration
  def up
    add_column :entries, :last_code, :text, :default => ""
  end

  def down
    remove_column :entries, :last_code
  end
end
