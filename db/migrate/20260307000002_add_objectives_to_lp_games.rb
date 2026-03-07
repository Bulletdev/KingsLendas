class AddObjectivesToLpGames < ActiveRecord::Migration[8.0]
  def change
    add_column :lp_games, :team1_towers,       :integer
    add_column :lp_games, :team2_towers,       :integer
    add_column :lp_games, :team1_inhibitors,   :integer
    add_column :lp_games, :team2_inhibitors,   :integer
    add_column :lp_games, :team1_dragons,      :integer
    add_column :lp_games, :team2_dragons,      :integer
    add_column :lp_games, :team1_barons,       :integer
    add_column :lp_games, :team2_barons,       :integer
    add_column :lp_games, :team1_rift_heralds, :integer
    add_column :lp_games, :team2_rift_heralds, :integer
    add_column :lp_games, :team1_void_grubs,   :integer
    add_column :lp_games, :team2_void_grubs,   :integer
    add_column :lp_games, :win_type,           :string
  end
end
