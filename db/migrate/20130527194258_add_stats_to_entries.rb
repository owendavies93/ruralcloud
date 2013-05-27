class AddStatsToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :evaluations, :integer, :default => 0
    add_column :entries, :failed_compilations, :integer, :default => 0
    add_column :entries, :failed_evaluations, :integer, :default => 0
  end
end
