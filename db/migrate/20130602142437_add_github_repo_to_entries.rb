class AddGithubRepoToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :github_repo, :string
  end
end
