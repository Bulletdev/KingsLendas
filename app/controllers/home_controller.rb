class HomeController < ApplicationController
  def index
    set_meta_tags(
      title: "Kings Lendas — Torneio Comunitário de LoL",
      description: "Acompanhe o IDL Kings Lendas Cup — o torneio comunitário de League of Legends do Baiano, com pros, streamers e amadores."
    )

    @schedule  = db_schedule
    @standings = leaguepedia.standings_from_schedule(@schedule)

    @next_match = find_next_match
    @recent_matches = find_recent_matches(3)
    @tournament_phase = detect_phase(@schedule)

    @scoreboard_players = db_players

    @top_stats = compute_top_stats(@scoreboard_players)
  end

  private

  def find_next_match
    now = Time.current.utc
    upcoming = @schedule.select do |m|
      dt = parse_utc(m["DateTime_UTC"])
      dt.is_a?(Time) && dt > now && m["Winner"].blank?
    end
    # Prefer matches where both teams are already determined
    known = upcoming.reject { |m| [ m["Team1"], m["Team2"] ].any? { |t| t.blank? || t == "TBD" } }
    (known.any? ? known : upcoming).min_by { |m| parse_utc(m["DateTime_UTC"]) }
  end

  def find_recent_matches(limit)
    @schedule.select { |m| m["Winner"].present? }
             .first(limit)
  end

  def detect_phase(schedule)
    phases = schedule.map { |m| m["Phase"] }.compact.uniq
    return "Final" if phases.any? { |p| p.include?("Final") }
    return "Semifinal" if phases.any? { |p| p.include?("Semi") }
    return "Quartas" if phases.any? { |p| p.include?("Quarter") || p.include?("Quarta") }
    "Fase de Grupos"
  end

  def compute_top_stats(players)
    return {} if players.blank?
    played = players.select { |p| p["Kills"].to_i + p["Deaths"].to_i + p["Assists"].to_i > 0 }
    return {} if played.blank?

    # Group by player
    by_player = played.group_by { |p| p["Link"] }

    # Most kills
    top_kills = by_player.transform_values { |games| games.sum { |g| g["Kills"].to_i } }
                         .max_by { |_, v| v }

    # Best KDA
    top_kda = by_player.transform_values do |games|
      deaths = games.sum { |g| g["Deaths"].to_i }
      kda = deaths.zero? ? (games.sum { |g| g["Kills"].to_i + g["Assists"].to_i }).to_f : (games.sum { |g| g["Kills"].to_i + g["Assists"].to_i }.to_f / deaths)
      { kda: kda.round(2), games: games.length }
    end.select { |_, v| v[:games] >= 2 }.max_by { |_, v| v[:kda] }

    # Most assists
    top_assists = by_player.transform_values { |games| games.sum { |g| g["Assists"].to_i } }
                           .max_by { |_, v| v }

    {
      kills:   { player: top_kills&.first,   value: top_kills&.last,           team: played.find { |p| p["Link"] == top_kills&.first }&.dig("Team") },
      kda:     { player: top_kda&.first,     value: top_kda&.last&.dig(:kda),  team: played.find { |p| p["Link"] == top_kda&.first }&.dig("Team") },
      assists: { player: top_assists&.first, value: top_assists&.last,         team: played.find { |p| p["Link"] == top_assists&.first }&.dig("Team") }
    }
  end

  def parse_utc(dt_str)
    return nil if dt_str.blank?
    Time.parse(dt_str).utc
  rescue ArgumentError
    nil
  end
end
