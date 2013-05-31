class AddUniqueSessionIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :unique_session_id, :string, :limit => 20
  end

  def self.down
    remove_column :users, :unique_session_id
  end
end
