# Leaguepedia CargoQuery API client
class LeaguepediaService
  BASE_URL = "https://lol.fandom.com/api.php"

  def initialize
    @conn = Faraday.new(BASE_URL) do |f|
      f.request :retry, max: 2, interval: 5, backoff_factor: 2,
                retry_statuses: [ 429, 500, 502, 503, 504 ]
      f.request :url_encoded
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  # Standings / TournamentResults
  # Returns [] when TournamentResults not populated yet (active group stage).
  # Callers should fall back to standings_from_schedule(schedule_data).
  def standings(tournament = CUP_TOURNAMENT)
    cargo_query(
      tables: "TournamentResults",
      fields: "Team,Place,Wins,Losses,Ties,Points",
      where:  "Tournament=\"#{tournament}\"",
      order_by: "Place ASC",
      limit: 20
    )
  end

  # Compute standings from already-fetched schedule data (no extra HTTP call)
  def standings_from_schedule(schedule_data)
    group   = schedule_data.reject { |m| m["Phase"].to_s.match?(/quarter|semi|final/i) }
    played  = group.select { |m| m["Winner"].present? }
    teams   = group.flat_map { |m| [ m["Team1"], m["Team2"] ] }
                   .reject { |t| t.blank? || t == "TBD" }.uniq
    teams.map do |team|
      matches = played.select { |m| m["Team1"] == team || m["Team2"] == team }
      wins    = matches.count { |m| m["Winner"] == team }
      losses  = matches.count { |m| m["Winner"] != team }
      { "Team" => team, "Wins" => wins.to_s, "Losses" => losses.to_s, "Place" => nil }
    end.sort_by { |s| [ -s["Wins"].to_i, s["Losses"].to_i ] }
  end

  # Match Schedule
  def schedule(overview_page = CUP_OVERVIEW_PAGE)
    raw = cargo_query(
      tables: "MatchSchedule",
      fields: "Team1,Team2,DateTime_UTC,BestOf,Winner,Team1Score,Team2Score,MatchDay,Phase",
      where:  "OverviewPage=\"#{overview_page}\"",
      order_by: "DateTime_UTC ASC",
      limit: 200
    )
    raw.map { |m| resolve_match_winner(m) }
  end

  # Scoreboard Games — use minimal safe fields
  def scoreboard_games(tournament = CUP_TOURNAMENT)
    raw = cargo_query(
      tables: "ScoreboardGames",
      fields: "UniqueGame,Tournament,Team1,Team2,Winner,Gamelength,DateTime_UTC," \
              "Team1Picks,Team2Picks,Team1Bans,Team2Bans," \
              "Team1Gold,Team2Gold,Team1Kills,Team2Kills,Patch",
      where:  "Tournament=\"#{tournament}\"",
      order_by: "DateTime_UTC ASC",
      limit: 500
    )
    raw.map { |g| resolve_game_winner(g) }
  end

  # Scoreboard Players
  def scoreboard_players(tournament = CUP_TOURNAMENT)
    cargo_query(
      tables: "ScoreboardPlayers",
      fields: "UniqueGame,Link,Champion,Kills,Deaths,Assists,CS,Gold,DamageToChampions,Team,Role,Side",
      where:  "Tournament=\"#{tournament}\"",
      order_by: "UniqueGame ASC",
      limit: 1000
    )
  end

  # Tournament Players / Rosters
  def tournament_players(overview_page = CUP_OVERVIEW_PAGE)
    cargo_query(
      tables: "TournamentPlayers",
      fields: "Player,Team,Role,IsSubstitute",
      where:  "OverviewPage=\"#{overview_page}\"",
      limit: 100
    )
  end

  # Champion Stats
  def champion_stats(overview_page = CUP_OVERVIEW_PAGE)
    cargo_query(
      tables: "ChampionStatsFromScoreboardGames",
      fields: "Champion,Picks,Bans,Wins,Games",
      where:  "OverviewPage=\"#{overview_page}\"",
      order_by: "Picks DESC",
      limit: 200
    )
  end

  # Tournaments listing
  def tournaments
    cargo_query(
      tables: "Tournaments",
      fields: "Name,DateStart,Date,League,Region,Teams,Prizepool",
      where:  "League LIKE \"%Kings Lendas%\"",
      order_by: "DateStart DESC",
      limit: 20
    )
  end

  private

  def cargo_query(tables:, fields:, where: nil, order_by: nil, limit: 100, offset: 0)
    params = {
      action:  "cargoquery",
      format:  "json",
      tables:  tables,
      fields:  fields,
      limit:   limit,
      offset:  offset
    }
    params[:where]    = where    if where
    params[:order_by] = order_by if order_by

    response = @conn.get("", params)
    return [] unless response.success?

    data = response.body
    return [] if data["error"]

    items = data["cargoquery"] || []
    # Normalize keys: spaces → underscores, skip precision meta fields
    items.filter_map do |item|
      title = item["title"]
      next unless title
      title.each_with_object({}) do |(k, v), h|
        next if k.end_with?("__precision")
        h[k.gsub(" ", "_")] = v
      end
    end
  rescue Faraday::Error => e
    Rails.logger.error("[LeaguepediaService] API error: #{e.message}")
    []
  end

  # Resolve Winner: "1" → Team1 name, "2" → Team2 name
  def resolve_match_winner(match)
    winner_side = match["Winner"].to_s
    team_name = case winner_side
    when "1" then match["Team1"]
    when "2" then match["Team2"]
    else nil
    end
    match.merge("Winner" => team_name, "Winner_Side" => winner_side)
  end

  def resolve_game_winner(game)
    winner_side = game["Winner"].to_s
    team_name = case winner_side
    when "1" then game["Team1"]
    when "2" then game["Team2"]
    else nil
    end
    game.merge("Winner" => team_name, "Winner_Side" => winner_side)
  end
end
