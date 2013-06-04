class AddTestScoreToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :test_score, :integer
  end
end
