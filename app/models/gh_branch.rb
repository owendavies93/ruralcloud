class GhBranch < ActiveRecord::Base
  attr_accessible :branch, :entry_id, :file_hash
end
