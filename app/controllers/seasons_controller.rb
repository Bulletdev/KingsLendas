class SeasonsController < ApplicationController
  def index
    set_meta_tags(title: "Temporadas — Kings Lendas")
    @seasons = SEASONS_DATA.map { |slug, data| { slug: slug, **data } }
  end

  def show
    @slug = params[:slug]
    @season_data = SEASONS_DATA[@slug]
    unless @season_data
      redirect_to seasons_path, alert: "Temporada não encontrada" and return
    end

    set_meta_tags(title: "#{@season_data[:label]} — Kings Lendas")

    tournament = @season_data[:leaguepedia_name]

    @standings = CacheService.fetch("standings:#{@slug}", :standings) do
      leaguepedia.standings(tournament)
    end

    # Use DB-backed schedule (persists after first successful fetch)
    @schedule = db_schedule(tournament)

    # Fallback 1: compute standings from schedule when TournamentResults is empty
    if @standings.blank? && @schedule.any?
      @standings = leaguepedia.standings_from_schedule(@schedule)
    end
    # Fallback 2: use static standings hardcoded in SEASONS_DATA
    @standings = @season_data[:static_standings] if @standings.blank? && @season_data[:static_standings]

    @champion_stats = CacheService.fetch("champion_stats:#{@slug}", :champion_stats) do
      leaguepedia.champion_stats(tournament)
    end.first(10)

    @players = CacheService.fetch("players:#{@slug}", :player_stats) do
      raw = leaguepedia.scoreboard_players(tournament)
      aggregate_season_players(raw)
    end.first(10)

    played   = @schedule.select { |m| m["Winner"].present? }
    upcoming = @schedule.reject { |m| m["Winner"].present? }

    # Group played matches by calendar date (newest first); upcoming at top if any
    sorted_dates = played.map { |m| m["DateTime_UTC"].to_s[0, 10] }.uniq.sort.reverse
    @matches_by_date = sorted_dates.map do |date|
      [ date, played.select { |m| m["DateTime_UTC"].to_s.start_with?(date) } ]
    end
    @upcoming_matches = upcoming
  end

  private

  def aggregate_season_players(raw)
    return [] if raw.blank?
    raw.group_by { |p| p["Link"] }.map do |player, games|
      kills   = games.sum { |g| g["Kills"].to_i }
      deaths  = games.sum { |g| g["Deaths"].to_i }
      assists = games.sum { |g| g["Assists"].to_i }
      kda     = deaths.zero? ? (kills + assists).to_f : (kills + assists).to_f / deaths
      {
        "player"    => player,
        "team"      => games.last["Team"],
        "role"      => games.last["Role"],
        "games"     => games.length,
        "kills"     => kills,
        "deaths"    => deaths,
        "assists"   => assists,
        "kda"       => kda.round(2),
        "avg_cs"    => (games.sum { |g| g["CS"].to_i }.to_f / games.length).round(1),
        "champions" => games.map { |g| g["Champion"] }.tally.sort_by { |_, v| -v }.first(3).map(&:first)
      }
    end.sort_by { |p| -p["kda"] }
  end
end
