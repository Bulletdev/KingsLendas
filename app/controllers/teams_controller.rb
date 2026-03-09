class TeamsController < ApplicationController
  CUP_TEAMS = %w[Team\ Sobe\ Muro SKTenis Mad\ Mylons Vôs\ Grandes Karmine\ Cospe Gen\ GG].freeze

  def index
    set_meta_tags(title: "Times — Kings Lendas Cup")
    @teams = TEAMS_DATA.select { |_, v| v.key?(:captain) }
    schedule = db_schedule
    @standings = leaguepedia.standings_from_schedule(schedule)
    @records = build_records(schedule)
  end

  def show
    @slug = params[:slug]
    @team_info = TEAMS_DATA.find { |_, v| v[:slug] == @slug }&.last
    unless @team_info
      redirect_to teams_path, alert: "Time não encontrado" and return
    end
    @team_name = TEAMS_DATA.find { |_, v| v[:slug] == @slug }&.first

    set_meta_tags(title: "#{@team_name} — Kings Lendas Cup")

    @schedule     = db_schedule
    @team_matches = @schedule.select { |m| m["Team1"] == @team_name || m["Team2"] == @team_name }
    @record = {
      wins:   @team_matches.count { |m| m["Winner"] == @team_name },
      losses: @team_matches.count { |m| m["Winner"].present? && m["Winner"] != @team_name }
    }

    @player_stats = aggregate_team_players(db_players.select { |p| p["Team"] == @team_name })

    @team_games = db_games.select { |g| g["Team1"] == @team_name || g["Team2"] == @team_name }
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
    picks = db_players.select { |p| p["Team"] == team_name }
                      .map { |p| p["Champion"] }.compact.reject(&:empty?)
    bans  = []
    team_games.each do |g|
      side = g["Team1"] == team_name ? "1" : "2"
      bans += g["Team#{side}Bans"].to_s.split(",").map { |b| b.strip.capitalize }.reject { |b| b.casecmp("none").zero? || b.empty? }
    end
    [
      picks.tally.sort_by { |_, v| -v }.first(5),
      bans.tally.sort_by  { |_, v| -v }.first(5)
    ]
  end
end
