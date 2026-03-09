class CupController < ApplicationController
  before_action :load_schedule_and_games

  def index
    set_meta_tags(
      title: "Kings Lendas Cup 2026",
      description: "Visão geral da Kings Lendas Cup — classificação, partidas e estatísticas."
    )
    @standings = load_standings
    @recent_matches = @schedule.select { |m| m["Winner"].present? }.first(5)
    @next_match = find_next_match
  end

  def standings
    set_meta_tags(title: "Classificação — Kings Lendas Cup")
    @standings = load_standings
    @form_map  = build_form_map(@schedule)
  end

  def matches
    set_meta_tags(title: "Partidas — Kings Lendas Cup")
    @games_by_unique = @games.index_by { |g| g["UniqueGame"] }
    played   = @schedule.select { |m| m["Winner"].present? }
    upcoming = @schedule.select { |m| m["Winner"].blank? }.sort_by { |m| m["DateTime_UTC"].to_s }
    @matches_grouped = (played + upcoming).group_by { |m| m["Phase"] || "Grupos" }
  end

  def draft
    set_meta_tags(title: "Picks & Bans — Kings Lendas Cup")
    @champion_stats = db_champions.sort_by { |c| -(c["Picks"].to_i + c["Bans"].to_i) }
    @teams = TEAMS_DATA.keys.first(6)
    @champ_teams = db_players
      .group_by { |p| p["Champion"] }
      .transform_values { |records| records.map { |r| r["Team"] }.uniq.join(",") }
  end

  def game_scoreboard
    unique_game = params[:id]
    @game    = @games.find { |g| g["UniqueGame"] == unique_game }
    return render plain: "", status: :not_found unless @game
    @players = db_players.select { |p| p["UniqueGame"] == unique_game }
                         .sort_by { |p| ROLE_ORDER.index(p["Role"]&.downcase) || 99 }
    @t1 = @game["Team1"]
    @t2 = @game["Team2"]
  end

  def champions
    set_meta_tags(title: "Campeões — Kings Lendas Cup")
    @sort_by = params[:sort] || "picks"
    @champion_stats = sort_champions(db_champions, @sort_by)
  end

  def players
    set_meta_tags(title: "Jogadores — Kings Lendas Cup")
    @sort_by = params[:sort] || "kda"
    raw = db_players
    if raw.any?
      @players = sort_players(aggregate_player_stats(raw), @sort_by)
    else
      @players = roster_players_fallback
    end
  end

  def results
    set_meta_tags(title: "Resultados — Kings Lendas Cup")
    @standings    = load_standings
    @teams_order  = @standings.map { |s| s["Team"] }
    @h2h          = build_h2h(@schedule)
    @streak_map   = build_streak_map(@schedule)

    @group_matches   = @schedule.reject { |m| playoff_phase?(m["Phase"]) || tbd_match?(m) }
    @playoff_matches = @schedule.select { |m| playoff_phase?(m["Phase"]) || tbd_match?(m) }

    # Group by calendar date so each real day gets its own section
    sorted_dates = @group_matches.map { |m| m["DateTime_UTC"].to_s[0, 10] }.uniq.sort
    @group_by_day = sorted_dates.each_with_index.each_with_object({}) do |(date, i), h|
      h[i + 1] = @group_matches.select { |m| m["DateTime_UTC"].to_s.start_with?(date) }
    end

    @playoff_by_phase = @playoff_matches
      .group_by { |m| m["Phase"] }
      .sort_by { |phase, _| playoff_phase_order(phase) }
      .to_h

    @games_by_unique = @games.index_by { |g| g["UniqueGame"] }
  end

  private

  def load_schedule_and_games
    @schedule = db_schedule
    @games    = db_games
  end

  def load_standings
    leaguepedia.standings_from_schedule(@schedule)
  end

  def find_next_match
    now = Time.current.utc
    @schedule.select { |m| (dt = parse_utc(m["DateTime_UTC"])) && dt > now && m["Winner"].blank? }
             .min_by { |m| parse_utc(m["DateTime_UTC"]) }
  end

  def build_form_map(schedule)
    played = schedule.select { |m| m["Winner"].present? }
    teams = TEAMS_DATA.keys.first(6)
    teams.each_with_object({}) do |team, hash|
      team_matches = played.select { |m| m["Team1"] == team || m["Team2"] == team }.first(5)
      hash[team] = team_matches.map { |m| m["Winner"] == team ? "W" : "L" }
    end
  end

  def roster_players_fallback
    TEAMS_DATA.flat_map do |team_name, td|
      (td[:roster] || []).map do |m|
        {
          "player"    => m[:player].to_s,
          "team"      => team_name,
          "role"      => m[:role].to_s,
          "games"     => 0,
          "kills"     => 0,
          "deaths"    => 0,
          "assists"   => 0,
          "kda"       => 0.0,
          "avg_cs"    => 0.0,
          "avg_gold"  => 0,
          "avg_dmg"   => 0,
          "champions" => []
        }
      end
    end
  end

  def aggregate_player_stats(raw)
    return [] if raw.blank?
    raw.group_by { |p| p["Link"] }.map do |player, games|
      kills   = games.sum { |g| g["Kills"].to_i }
      deaths  = games.sum { |g| g["Deaths"].to_i }
      assists = games.sum { |g| g["Assists"].to_i }
      kda     = deaths.zero? ? (kills + assists).to_f : (kills + assists).to_f / deaths
      {
        "player"   => player,
        "team"     => games.group_by { |g| g["Team"] }.max_by { |_, gs| gs.length }.first,
        "role"     => games.last["Role"],
        "games"    => games.length,
        "kills"    => kills,
        "deaths"   => deaths,
        "assists"  => assists,
        "kda"      => kda.round(2),
        "avg_cs"   => (games.sum { |g| g["CS"].to_i }.to_f / games.length).round(1),
        "avg_gold" => (games.sum { |g| g["Gold"].to_i }.to_f / games.length).round(0),
        "avg_dmg"  => (games.sum { |g| g["DamageToChampions"].to_i }.to_f / games.length).round(0),
        "champions" => games.map { |g| g["Champion"] }.tally.sort_by { |_, v| -v }.first(3).map(&:first)
      }
    end
  end

  def sort_players(players, sort_by)
    case sort_by
    when "kills"   then players.sort_by { |p| -p["kills"] }
    when "deaths"  then players.sort_by { |p| p["deaths"] }
    when "assists" then players.sort_by { |p| -p["assists"] }
    when "cs"      then players.sort_by { |p| -p["avg_cs"] }
    when "gold"    then players.sort_by { |p| -p["avg_gold"] }
    when "games"   then players.sort_by { |p| -p["games"] }
    else players.sort_by { |p| -p["kda"] }
    end
  end

  def sort_champions(champs, sort_by)
    case sort_by
    when "bans"   then champs.sort_by { |c| -c["Bans"].to_i }
    when "wins"   then champs.sort_by { |c| -c["Wins"].to_i }
    when "games"  then champs.sort_by { |c| -c["Games"].to_i }
    when "winpct" then champs.sort_by { |c| c["Games"].to_i > 0 ? -(c["Wins"].to_f / c["Games"].to_i * 100) : 0 }
    else champs.sort_by { |c| -c["Picks"].to_i }
    end
  end

  def parse_utc(dt_str)
    return nil if dt_str.blank?
    Time.parse(dt_str).utc
  rescue ArgumentError
    nil
  end

  def tbd_match?(match)
    match["Team1"].to_s.strip.casecmp?("tbd") || match["Team2"].to_s.strip.casecmp?("tbd")
  end

  def playoff_phase?(phase)
    phase.to_s.match?(/quarter|semi|final/i)
  end

  def playoff_phase_order(phase)
    return 0 if phase.to_s.match?(/quarter/i)
    return 1 if phase.to_s.match?(/semi/i)
    2
  end

  def build_h2h(schedule)
    played     = schedule.select { |m| m["Winner"].present? && !playoff_phase?(m["Phase"]) }
    cup_teams  = TEAMS_DATA.keys.first(6)
    h = cup_teams.each_with_object({}) do |t, hash|
      hash[t] = cup_teams.each_with_object({}) { |t2, h2| h2[t2] = { wins: 0, losses: 0 } }
    end
    played.each do |m|
      t1, t2, winner = m["Team1"], m["Team2"], m["Winner"]
      next unless t1.present? && t2.present? && winner.present?
      if winner == t1
        h[t1][t2][:wins]   += 1 if h[t1] && h[t1][t2]
        h[t2][t1][:losses] += 1 if h[t2] && h[t2][t1]
      elsif winner == t2
        h[t2][t1][:wins]   += 1 if h[t2] && h[t2][t1]
        h[t1][t2][:losses] += 1 if h[t1] && h[t1][t2]
      end
    end
    h
  end

  def build_streak_map(schedule)
    played    = schedule.select { |m| m["Winner"].present? && !playoff_phase?(m["Phase"]) }
    cup_teams = TEAMS_DATA.keys.first(6)
    cup_teams.each_with_object({}) do |team, map|
      team_games = played
        .select { |m| m["Team1"] == team || m["Team2"] == team }
        .sort_by { |m| m["DateTime_UTC"].to_s }
      streak = 0
      streak_type = nil
      team_games.reverse_each do |m|
        result = m["Winner"] == team ? "W" : "L"
        if streak_type.nil?
          streak_type = result
          streak = 1
        elsif result == streak_type
          streak += 1
        else
          break
        end
      end
      map[team] = streak_type ? "#{streak}#{streak_type}" : "—"
    end
  end
end
