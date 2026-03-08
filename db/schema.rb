# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_07_000002) do
  create_table "lp_champion_stats", force: :cascade do |t|
    t.string "tournament", null: false
    t.string "champion", null: false
    t.integer "picks", default: 0
    t.integer "bans", default: 0
    t.integer "wins", default: 0
    t.integer "games", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament", "champion"], name: "index_lp_champion_stats_on_tournament_and_champion", unique: true
  end

  create_table "lp_games", force: :cascade do |t|
    t.string "unique_game", null: false
    t.string "tournament"
    t.string "team1"
    t.string "team2"
    t.string "winner"
    t.string "gamelength"
    t.string "datetime_utc"
    t.text "team1_picks"
    t.text "team2_picks"
    t.text "team1_bans"
    t.text "team2_bans"
    t.integer "team1_kills"
    t.integer "team2_kills"
    t.integer "team1_gold"
    t.integer "team2_gold"
    t.string "patch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team1_towers"
    t.integer "team2_towers"
    t.integer "team1_inhibitors"
    t.integer "team2_inhibitors"
    t.integer "team1_dragons"
    t.integer "team2_dragons"
    t.integer "team1_barons"
    t.integer "team2_barons"
    t.integer "team1_rift_heralds"
    t.integer "team2_rift_heralds"
    t.integer "team1_void_grubs"
    t.integer "team2_void_grubs"
    t.string "win_type"
    t.index ["tournament"], name: "index_lp_games_on_tournament"
    t.index ["unique_game"], name: "index_lp_games_on_unique_game", unique: true
  end

  create_table "lp_matches", force: :cascade do |t|
    t.string "overview_page", null: false
    t.string "team1"
    t.string "team2"
    t.string "datetime_utc"
    t.integer "best_of"
    t.string "winner"
    t.integer "team1_score"
    t.integer "team2_score"
    t.integer "match_day"
    t.string "phase"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["datetime_utc"], name: "index_lp_matches_on_datetime_utc"
    t.index ["overview_page"], name: "index_lp_matches_on_overview_page"
  end

  create_table "lp_players", force: :cascade do |t|
    t.string "unique_game", null: false
    t.string "tournament"
    t.string "player_link"
    t.string "champion"
    t.integer "kills"
    t.integer "deaths"
    t.integer "assists"
    t.integer "cs"
    t.integer "gold"
    t.integer "damage_to_champions"
    t.string "team"
    t.string "role"
    t.string "side"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_link"], name: "index_lp_players_on_player_link"
    t.index ["tournament"], name: "index_lp_players_on_tournament"
    t.index ["unique_game", "player_link"], name: "index_lp_players_on_unique_game_and_player_link", unique: true
  end

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "lp_players_fts", "fts5", ["player_link", "team", "content='lp_players'", "content_rowid='id'"]
end
