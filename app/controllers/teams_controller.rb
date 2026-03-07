class TeamsController < ApplicationController
  CUP_TEAMS = %w[Team\ Sobe\ Muro SKTenis Mad\ Mylons Vôs\ Grandes Karmine\ Cospe Gen\ GG].freeze

  def index
    set_meta_tags(title: "Times — Kings Lendas Cup")
    @standings = CacheService.fetch("standings:cup", :standings) { leaguepedia.standings }
    @teams = TEAMS_DATA.select { |_, v| v.key?(:captain) }
    @schedule = CacheService.fetch("schedule:cup", :schedule) { leaguepedia.schedule }
    @records = build_records(@schedule)
  end

  def show
    @slug = params[:slug]
    @team_info = TEAMS_DATA.find { |_, v| v[:slug] == @slug }&.last
    unless @team_info
      redirect_to teams_path, alert: "Time não encontrado" and return
    end
    @team_name = TEAMS_DATA.find { |_, v| v[:slug] == @slug }&.first

    set_meta_tags(title: "#{@team_name} — Kings Lendas Cup")

    @schedule = CacheService.fetch("schedule:cup", :schedule) { leaguepedia.schedule }
    @team_matches = @schedule.select { |m| m["Team1"] == @team_name || m["Team2"] == @team_name }
    @record = {
      wins:   @team_matches.count { |m| m["Winner"] == @team_name },
      losses: @team_matches.count { |m| m["Winner"].present? && m["Winner"] != @team_name }
    }

    raw_players = CacheService.fetch("players:cup", :player_stats) { leaguepedia.scoreboard_players }
    @player_stats = aggregate_team_players(raw_players.select { |p| p["Team"] == @team_name })

    @games = CacheService.fetch("games:cup", :match_details) { leaguepedia.scoreboard_games }
    @team_games = @games.select { |g| g["Team1"] == @team_name || g["Team2"] == @team_name }
    @fav_picks, @fav_bans = favorite_picks_bans(@team_games, @team_name)
  end

  private

  def build_records(schedule)
    played = schedule.select { |m| m["Winner"].present? }
    TEAMS_DATA.transform_values do |_|
      team_name = TEAMS_DATA.find { |_, v| v == _ }&.first
      team_matches = played.select { |m| m["Team1"] == team_name || m["Team2"] == team_name }
      {
        wins:   team_matches.count { |m| m["Winner"] == team_name },
        losses: team_matches.count { |m| m["Winner"] != team_name }
      }
    end
  end

  def aggregate_team_players(raw)
    raw.group_by { |p| p["Link"] }.map do |player, games|
      kills   = games.sum { |g| g["Kills"].to_i }
      deaths  = games.sum { |g| g["Deaths"].to_i }
      assists = games.sum { |g| g["Assists"].to_i }
      kda     = deaths.zero? ? (kills + assists).to_f : (kills + assists).to_f / deaths
      {
        "player"    => player,
        "role"      => games.last["Role"],
        "games"     => games.length,
        "kda"       => kda.round(2),
        "avg_kills" => (kills.to_f / games.length).round(1),
        "avg_deaths"=> (deaths.to_f / games.length).round(1),
        "avg_assists"=> (assists.to_f / games.length).round(1),
        "avg_cs"    => (games.sum { |g| g["CS"].to_i }.to_f / games.length).round(1),
        "champions" => games.map { |g| g["Champion"] }.tally.sort_by { |_, v| -v }.first(3).map(&:first)
      }
    end.sort_by { |p| ROLE_ORDER.index(p["role"]&.downcase) || 99 }
  end

  def favorite_picks_bans(team_games, team_name)
    picks = []
    bans  = []
    team_games.each do |g|
      side = g["Team1"] == team_name ? "1" : "2"
      opp  = side == "1" ? "2" : "1"
      picks += g["Team#{side}Picks"].to_s.split(",").map(&:strip)
      bans  += g["Team#{side}Bans"].to_s.split(",").map(&:strip)
    end
    [
      picks.tally.sort_by { |_, v| -v }.first(5),
      bans.tally.sort_by  { |_, v| -v }.first(5)
    ]
  end
end
