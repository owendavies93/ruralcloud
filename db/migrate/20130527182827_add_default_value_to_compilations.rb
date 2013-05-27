class AddDefaultValueToCompilations < ActiveRecord::Migration
  def up
    change_column :entries, :compilations, :integer, :default => 0
  end

  def down
    change_column :entries, :compilations, :integer, :default => nil
  end
end
