class LeaguepediaSyncService
  def initialize(overview_page: CUP_OVERVIEW_PAGE, tournament: CUP_TOURNAMENT)
    @overview_page = overview_page
    @tournament    = tournament
    @api           = LeaguepediaService.new
  end

  def sync_all
    results = {}
    results[:matches]  = sync_matches
    results[:games]    = sync_games
    results[:players]  = sync_players
    results[:champions]= sync_champions
    Rails.cache.clear
    DdragonService.version  # re-warm DDragon version cache after clear
    results
  end

  def sync_matches
    raw = @api.schedule(@overview_page)
    return 0 if raw.empty?

    LpMatch.where(overview_page: @overview_page).delete_all

    rows = raw.map do |m|
      {
        overview_page: @overview_page,
        team1:         m["Team1"].to_s,
        team2:         m["Team2"].to_s,
        datetime_utc:  m["DateTime_UTC"].to_s,
        best_of:       m["BestOf"].to_i,
        winner:        m["Winner"].to_s,
        team1_score:   m["Team1Score"].to_i,
        team2_score:   m["Team2Score"].to_i,
        match_day:     m["MatchDay"].to_i,
        phase:         m["Phase"].to_s,
        created_at:    Time.current,
        updated_at:    Time.current
      }
    end

    LpMatch.insert_all!(rows)
    rows.length
  end

  def sync_games
    raw = @api.scoreboard_games(@tournament)

    if raw.empty?
      Rails.logger.warn("[LeaguepediaSyncService] Cargo ScoreboardGames empty — trying WikitextService fallback")
      raw = LeaguepediaWikitextService.new.all_games
      Rails.logger.info("[LeaguepediaSyncService] WikitextService returned #{raw.length} games")
    end

    return 0 if raw.empty?

    # Fetch objectives in a separate query to avoid MWException (only for Cargo data)
    objectives = {}
    begin
      sleep 1
      objectives = @api.scoreboard_objectives(@tournament)
    rescue => e
      Rails.logger.warn("[LeaguepediaSyncService] objectives fetch failed: #{e.message}")
    end

    rows = raw.filter_map do |g|
      next if g["UniqueGame"].blank?
      obj = objectives[g["UniqueGame"]] || {}
      {
        unique_game:  g["UniqueGame"],
        tournament:   @tournament,
        team1:        g["Team1"].to_s,
        team2:        g["Team2"].to_s,
        winner:       g["Winner"].to_s,
        gamelength:   g["Gamelength"].to_s,
        datetime_utc: g["DateTime_UTC"].to_s,
        team1_picks:  g["Team1Picks"].to_s,
        team2_picks:  g["Team2Picks"].to_s,
        team1_bans:   g["Team1Bans"].to_s,
        team2_bans:   g["Team2Bans"].to_s,
        team1_kills:        g["Team1Kills"].to_i,
        team2_kills:        g["Team2Kills"].to_i,
        team1_gold:         g["Team1Gold"].to_i,
        team2_gold:         g["Team2Gold"].to_i,
        patch:              g["Patch"].to_s,
        win_type:           g["WinType"].to_s,
        team1_towers:       obj["Team1Towers"].presence&.to_i,
        team2_towers:       obj["Team2Towers"].presence&.to_i,
        team1_inhibitors:   obj["Team1Inhibitors"].presence&.to_i,
        team2_inhibitors:   obj["Team2Inhibitors"].presence&.to_i,
        team1_dragons:      obj["Team1Dragons"].presence&.to_i,
        team2_dragons:      obj["Team2Dragons"].presence&.to_i,
        team1_barons:       obj["Team1Barons"].presence&.to_i,
        team2_barons:       obj["Team2Barons"].presence&.to_i,
        team1_rift_heralds: obj["Team1RiftHeralds"].presence&.to_i,
        team2_rift_heralds: obj["Team2RiftHeralds"].presence&.to_i,
        team1_void_grubs:   obj["Team1VoidGrubs"].presence&.to_i,
        team2_void_grubs:   obj["Team2VoidGrubs"].presence&.to_i,
        created_at:         Time.current,
        updated_at:         Time.current
      }
    end

    LpGame.upsert_all(rows, unique_by: :unique_game) if rows.any?
    rows.length
  end

  def sync_players
    raw = @api.scoreboard_players(@tournament)

    if raw.empty?
      Rails.logger.warn("[LeaguepediaSyncService] Cargo ScoreboardPlayers empty — trying WikitextService fallback")
      raw = LeaguepediaWikitextService.new.all_players
      Rails.logger.info("[LeaguepediaSyncService] WikitextService returned #{raw.length} player rows")
    end

    return 0 if raw.empty?

    rows = raw.filter_map do |p|
      next if p["UniqueGame"].blank? || p["Link"].blank?
      {
        unique_game:        p["UniqueGame"],
        tournament:         @tournament,
        player_link:        p["Link"].to_s,
        champion:           p["Champion"].to_s,
        kills:              p["Kills"].to_i,
        deaths:             p["Deaths"].to_i,
        assists:            p["Assists"].to_i,
        cs:                 p["CS"].to_i,
        gold:               p["Gold"].to_i,
        damage_to_champions: p["DamageToChampions"].to_i,
        team:               p["Team"].to_s,
        role:               p["Role"].to_s,
        side:               p["Side"].to_s,
        created_at:         Time.current,
        updated_at:         Time.current
      }
    end

    LpPlayer.where(tournament: @tournament).delete_all
    LpPlayer.insert_all!(rows) if rows.any?

    # Rebuild FTS index
    ActiveRecord::Base.connection.execute("DELETE FROM lp_players_fts")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO lp_players_fts(rowid, player_link, team) SELECT id, player_link, team FROM lp_players"
    )

    rows.length
  end

  def sync_champions
    raw = @api.champion_stats(@tournament)
    return 0 if raw.empty?

    LpChampionStat.where(tournament: @tournament).delete_all

    rows = raw.map do |c|
      {
        tournament: @tournament,
        champion:   c["Champion"].to_s,
        picks:      c["Picks"].to_i,
        bans:       c["Bans"].to_i,
        wins:       c["Wins"].to_i,
        games:      c["Games"].to_i,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    LpChampionStat.insert_all!(rows) if rows.any?
    rows.length
  end
end
