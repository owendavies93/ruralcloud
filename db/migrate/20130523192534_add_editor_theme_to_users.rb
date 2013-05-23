class AddEditorThemeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :editor_theme, :string, :default => "default"
  end

  def self.down
    remove_column :users, :editor_theme
  end
end
