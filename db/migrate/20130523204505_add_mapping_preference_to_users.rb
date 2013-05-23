class AddMappingPreferenceToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mapping_preference, :string
  end
end
