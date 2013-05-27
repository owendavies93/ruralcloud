class ChangeLogToText < ActiveRecord::Migration
  def up
    change_column :challenges, :log, :text
  end

  def down
    # NB: this might delete logs if they are longer than 255 chars
    change_column :challenges, :log, :string
  end
end
