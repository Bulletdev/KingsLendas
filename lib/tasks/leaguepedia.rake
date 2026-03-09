namespace :leaguepedia do
  desc "Sync all data from Leaguepedia into SQLite (skips if DB already populated and no new matches)"
  task sync: :environment do
    svc = LeaguepediaSyncService.new

    db_count  = LpMatch.where(overview_page: CUP_OVERVIEW_PAGE).count
    api_count = LeaguepediaService.new.schedule(CUP_OVERVIEW_PAGE).length

    if db_count > 0 && db_count == api_count
      played_db  = LpMatch.where(overview_page: CUP_OVERVIEW_PAGE).where.not(winner: [ nil, "" ]).count
      played_api = LeaguepediaService.new.schedule(CUP_OVERVIEW_PAGE).count { |m| m["Winner"].present? }

      if played_db == played_api
        puts "DB up to date (#{db_count} matches, #{played_db} played). Skipping sync."
        next
      end
    end

    puts "Syncing Leaguepedia data..."
    results = svc.sync_all
    results.each { |k, v| puts "  #{k}: #{v} rows" }
    puts "Done."
  end

  desc "Force sync all data regardless of DB state"
  task sync_force: :environment do
    puts "Force syncing Leaguepedia data..."
    results = LeaguepediaSyncService.new.sync_all
    results.each { |k, v| puts "  #{k}: #{v} rows" }
    puts "Done."
  end

  desc "Sync only matches (schedule)"
  task sync_matches: :environment do
    n = LeaguepediaSyncService.new.sync_matches
    puts "Synced #{n} matches."
  end

  desc "Sync only games (scoreboard)"
  task sync_games: :environment do
    n = LeaguepediaSyncService.new.sync_games
    puts "Synced #{n} games."
  end

  desc "Sync only player stats"
  task sync_players: :environment do
    n = LeaguepediaSyncService.new.sync_players
    Rails.cache.delete_matched("kl:players*")
    puts "Synced #{n} player rows."
  end

  desc "Sync only champion stats"
  task sync_champions: :environment do
    n = LeaguepediaSyncService.new.sync_champions
    Rails.cache.delete_matched("kl:champion_stats*")
    puts "Synced #{n} champion stat rows."
  end

  desc "Bootstrap production DB: sync schedule + import stats + fix dates (idempotent)"
  task bootstrap: :environment do
    tournament = CUP_TOURNAMENT
    overview   = CUP_OVERVIEW_PAGE

    # ── 1. Sync match schedule from Leaguepedia API (if not yet populated) ──
    if LpMatch.where(overview_page: overview).count == 0
      puts "Syncing match schedule..."
      begin
        n = LeaguepediaSyncService.new.sync_matches
        puts "  #{n} match rows synced."
      rescue => e
        puts "  WARNING: match sync failed: #{e.message}"
      end
    else
      puts "  match schedule already populated (#{LpMatch.where(overview_page: overview).count} rows), skipping."
    end

    # ── 2. Fix match_day and phase based on date (Leaguepedia stored 2025 for 2026) ──
    date_map = {
      "2025-03-06" => { match_day: 1,   phase: nil },
      "2026-03-06" => { match_day: 1,   phase: nil },
      "2025-03-07" => { match_day: 2,   phase: nil },
      "2026-03-07" => { match_day: 2,   phase: nil },
      "2025-03-08" => { match_day: 3,   phase: nil },
      "2026-03-08" => { match_day: 3,   phase: nil },
      "2025-03-15" => { match_day: nil, phase: "Finals" },
      "2026-03-15" => { match_day: nil, phase: "Finals" },
      "2026-03-13" => { match_day: nil, phase: "Quarterfinals" },
      "2026-03-14" => { match_day: nil, phase: "Semifinals" }
    }
    LpMatch.where(overview_page: overview).each do |m|
      date_str = m.datetime_utc.to_s[0, 10]
      # Fix year: Leaguepedia stores 2025 for what is actually 2026
      if date_str.start_with?("2025-03-0")
        corrected = date_str.sub("2025-", "2026-")
        m.update_column(:datetime_utc, m.datetime_utc.to_s.sub("2025-", "2026-"))
        date_str = corrected
      end
      if (attrs = date_map[date_str])
        m.update_columns(match_day: attrs[:match_day], phase: attrs[:phase])
      end
    end

    # ── 3. Import champion + player + game stats from devdocs/import_data.json ──
    data_file = Rails.root.join("devdocs", "import_data.json")
    if data_file.exist?
      Rake::Task["leaguepedia:import_html"].invoke
    else
      puts "devdocs/import_data.json not found — skipping stats import."
    end

    # ── 4. Sync past season schedules ──
    puts "Syncing past season schedules..."
    Rake::Task["leaguepedia:sync_seasons"].invoke

    # ── 5. Clear cache so first web request gets fresh DB data ──
    Rails.cache.clear rescue nil
    DdragonService.version rescue nil

    puts "Bootstrap complete."
  end

  desc "Import Day 1 data from saved HTML files in devdocs/"
  task import_html: :environment do
    require "json"

    data_file = Rails.root.join("devdocs", "import_data.json")
    unless data_file.exist?
      puts "ERROR: #{data_file} not found. Run the Python parser first."
      next
    end

    data = JSON.parse(data_file.read)
    tournament = "IDL Kings Lendas Cup"

    # Champion Stats
    puts "Importing champion stats..."
    champ_count = 0
    data["champion_stats"].each do |c|
      LpChampionStat.find_or_initialize_by(tournament: tournament, champion: c["champion"]).tap do |rec|
        rec.picks = c["picks"]
        rec.bans  = c["bans"]
        rec.wins  = c["wins"]
        rec.games = c["games"]
        rec.save!
        champ_count += 1
      end
    end
    puts "  #{champ_count} champion stat rows upserted."

    # Games
    puts "Importing games..."
    game_count = 0
    data["game_records"].each do |g|
      LpGame.find_or_initialize_by(unique_game: g["unique_game"]).tap do |rec|
        rec.tournament   = tournament
        rec.team1        = g["team1"]
        rec.team2        = g["team2"]
        rec.winner       = g["winner"]
        rec.gamelength   = g["gamelength"]
        rec.team1_picks  = g["team1_picks"]
        rec.team2_picks  = g["team2_picks"]
        rec.team1_kills  = g["team1_kills"]
        rec.team2_kills  = g["team2_kills"]
        rec.team1_gold   = g["team1_gold"]
        rec.team2_gold   = g["team2_gold"]
        rec.save!
        game_count += 1
      end
    end
    puts "  #{game_count} game rows upserted."

    # Players
    puts "Importing player stats..."
    player_count = 0
    data["player_records"].each do |p|
      LpPlayer.find_or_initialize_by(unique_game: p["game_id"], player_link: p["player_link"]).tap do |rec|
        rec.tournament          = tournament
        rec.champion            = p["champion"]
        rec.kills               = p["kills"]
        rec.deaths              = p["deaths"]
        rec.assists             = p["assists"]
        rec.cs                  = p["cs"]
        rec.gold                = p["gold"]
        rec.damage_to_champions = p["dmg"]
        rec.team                = p["team"]
        rec.role                = p["role"]
        rec.save!
        player_count += 1
      end
    end

    # Rebuild FTS index
    ActiveRecord::Base.connection.execute("INSERT INTO lp_players_fts(lp_players_fts) VALUES('rebuild')")
    puts "  #{player_count} player rows upserted."

    # Clear stale player/champion/games cache so next request reads fresh DB data
    Rails.cache.delete_matched("kl:players*")
    Rails.cache.delete_matched("kl:champion_stats*")
    Rails.cache.delete_matched("kl:games*")
    puts "Cache cleared."
    puts "Done."
  end

  desc "Create lp_* tables in Supabase (leaguepedia DB) — idempotent"
  task setup_supabase: :environment do
    conn = LeaguepediaRecord.connection

    unless conn.table_exists?(:lp_matches)
      conn.create_table :lp_matches do |t|
        t.string  :overview_page, null: false
        t.string  :team1
        t.string  :team2
        t.string  :datetime_utc
        t.integer :best_of
        t.string  :winner
        t.integer :team1_score
        t.integer :team2_score
        t.integer :match_day
        t.string  :phase
        t.timestamps
      end
      conn.add_index :lp_matches, :overview_page
      conn.add_index :lp_matches, :datetime_utc
      puts "  created lp_matches"
    else
      puts "  lp_matches already exists"
    end

    unless conn.table_exists?(:lp_games)
      conn.create_table :lp_games do |t|
        t.string  :unique_game, null: false
        t.string  :tournament
        t.string  :team1
        t.string  :team2
        t.string  :winner
        t.string  :gamelength
        t.string  :datetime_utc
        t.text    :team1_picks
        t.text    :team2_picks
        t.text    :team1_bans
        t.text    :team2_bans
        t.integer :team1_kills
        t.integer :team2_kills
        t.integer :team1_gold
        t.integer :team2_gold
        t.string  :patch
        t.integer :team1_towers
        t.integer :team2_towers
        t.integer :team1_inhibitors
        t.integer :team2_inhibitors
        t.integer :team1_dragons
        t.integer :team2_dragons
        t.integer :team1_barons
        t.integer :team2_barons
        t.integer :team1_rift_heralds
        t.integer :team2_rift_heralds
        t.integer :team1_void_grubs
        t.integer :team2_void_grubs
        t.string  :win_type
        t.timestamps
      end
      conn.add_index :lp_games, :unique_game, unique: true
      conn.add_index :lp_games, :tournament
      puts "  created lp_games"
    else
      puts "  lp_games already exists"
    end

    unless conn.table_exists?(:lp_players)
      conn.create_table :lp_players do |t|
        t.string  :unique_game, null: false
        t.string  :tournament
        t.string  :player_link
        t.string  :champion
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
      conn.add_index :lp_players, [ :unique_game, :player_link ], unique: true
      conn.add_index :lp_players, :tournament
      conn.add_index :lp_players, :player_link
      puts "  created lp_players"
    else
      puts "  lp_players already exists"
    end

    unless conn.table_exists?(:lp_champion_stats)
      conn.create_table :lp_champion_stats do |t|
        t.string  :tournament, null: false
        t.string  :champion,   null: false
        t.integer :picks,  default: 0
        t.integer :bans,   default: 0
        t.integer :wins,   default: 0
        t.integer :games,  default: 0
        t.timestamps
      end
      conn.add_index :lp_champion_stats, [ :tournament, :champion ], unique: true
      puts "  created lp_champion_stats"
    else
      puts "  lp_champion_stats already exists"
    end

    puts "Supabase setup complete."
  end

  desc "Sync past season match schedules (Seasons 1, 2, 3) into DB — idempotent with retries"
  task sync_seasons: :environment do
    seasons = SEASONS_DATA.reject { |slug, _| slug == "copa" }

    seasons.each do |slug, data|
      overview_page = data[:leaguepedia_name]
      existing = LpMatch.where(overview_page: overview_page).count

      if existing > 0
        puts "#{slug} (#{overview_page}): already #{existing} matches — skipping"
        next
      end

      puts "#{slug} (#{overview_page}): syncing..."
      attempts = 0
      loop do
        attempts += 1
        begin
          result = LeaguepediaSyncService.new(overview_page: overview_page).sync_matches
          if result > 0
            puts "  synced #{result} matches"
            break
          else
            puts "  attempt #{attempts}: API returned empty (rate limit?)"
            break if attempts >= 3
            puts "  waiting 30s before retry..."
            sleep 30
          end
        rescue => e
          puts "  attempt #{attempts}: ERROR #{e.message}"
          break if attempts >= 3
          sleep 15
        end
      end

      sleep 2 # brief pause between seasons
    end

    puts "\nSeason sync complete."
    puts "DB counts:"
    seasons.each do |slug, data|
      n = LpMatch.where(overview_page: data[:leaguepedia_name]).count
      puts "  #{slug}: #{n} matches"
    end
  end

  desc "Show current DB counts"
  task status: :environment do
    puts "DB Status (Cup):"
    puts "  matches:  #{LpMatch.where(overview_page: CUP_OVERVIEW_PAGE).count}"
    puts "  games:    #{LpGame.where(tournament: CUP_TOURNAMENT).count}"
    puts "  players:  #{LpPlayer.where(tournament: CUP_TOURNAMENT).count}"
    puts "  champions:#{LpChampionStat.where(tournament: CUP_TOURNAMENT).count}"
    puts "\nDB Status (Seasons):"
    SEASONS_DATA.reject { |s, _| s == "copa" }.each do |slug, data|
      n = LpMatch.where(overview_page: data[:leaguepedia_name]).count
      puts "  #{slug}: #{n} matches"
    end
    puts "\n  DB: #{ActiveRecord::Base.connection_db_config.database}"
  end
end
