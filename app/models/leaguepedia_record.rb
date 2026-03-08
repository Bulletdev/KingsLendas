class LeaguepediaRecord < ApplicationRecord
  self.abstract_class = true

  if ActiveRecord::Base.configurations.find_db_config("leaguepedia")
    connects_to database: { writing: :leaguepedia, reading: :leaguepedia }
  end
end
