class CreateLeaguepediaTables < ActiveRecord::Migration[8.0]
  def change
    create_table :lp_matches do |t|
      t.string :overview_page, null: false
      t.string :team1
      t.string :team2
      t.string :datetime_utc
      t.integer :best_of
      t.string :winner
      t.integer :team1_score
      t.integer :team2_score
      t.integer :match_day
      t.string :phase
      t.timestamps
    end
    add_index :lp_matches, :overview_page
    add_index :lp_matches, :datetime_utc

    create_table :lp_games do |t|
      t.string :unique_game, null: false
      t.string :tournament
      t.string :team1
      t.string :team2
      t.string :winner
      t.string :gamelength
      t.string :datetime_utc
      t.text   :team1_picks
      t.text   :team2_picks
      t.text   :team1_bans
      t.text   :team2_bans
      t.integer :team1_kills
      t.integer :team2_kills
      t.integer :team1_gold
      t.integer :team2_gold
      t.string  :patch
      t.timestamps
    end
    add_index :lp_games, :unique_game, unique: true
    add_index :lp_games, :tournament

    create_table :lp_players do |t|
      t.string :unique_game, null: false
      t.string :tournament
      t.string :player_link
      t.string :champion
      t.integer :kills
      t.integer :deaths
      t.integer :assists
      t.integer :cs
      t.integer :gold
      t.integer :damage_to_champions
      t.string  :team
      t.string  :role
      t.string  :side
      t.timestamps
    end
    add_index :lp_players, [ :unique_game, :player_link ], unique: true
    add_index :lp_players, :tournament
    add_index :lp_players, :player_link

    create_table :lp_champion_stats do |t|
      t.string  :tournament, null: false
      t.string  :champion,   null: false
      t.integer :picks,    default: 0
      t.integer :bans,     default: 0
      t.integer :wins,     default: 0
      t.integer :games,    default: 0
      t.timestamps
    end
    add_index :lp_champion_stats, [ :tournament, :champion ], unique: true

    # FTS5 virtual table for player search
    execute <<~SQL
      CREATE VIRTUAL TABLE lp_players_fts
      USING fts5(player_link, team, content='lp_players', content_rowid='id');
    SQL
  end
end
