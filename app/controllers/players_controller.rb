class PlayersController < ApplicationController
  def show
    @slug = params[:slug]
    @player_name = @slug.gsub("-", " ")

    raw_players = db_players
    player_games = raw_players.select { |p| p["Link"].to_s.downcase == @player_name.downcase ||
                                             p["Link"].to_s.parameterize == @slug }

    if player_games.empty?
      # Try case-insensitive slug match
      player_games = raw_players.select { |p| p["Link"].to_s.parameterize.include?(@slug) }
    end

    if player_games.empty?
      # Fall back to TEAMS_DATA roster — player may not have game data yet
      roster_entry = nil
      roster_team  = nil
      TEAMS_DATA.each do |team_name, td|
        member = td[:roster]&.find { |m| m[:player].to_s.parameterize == @slug }
        if member
          roster_entry = member
          roster_team  = team_name
          break
        end
      end

      if roster_entry.nil?
        redirect_to cup_players_path, alert: "Jogador não encontrado" and return
      end

      @player_name = roster_entry[:player]
      @player_team = roster_team
      @player_role = roster_entry[:role]
      @team_info   = team_data(@player_team)
      @is_captain  = roster_entry[:captain] || TEAMS_DATA[@player_team]&.dig(:captain) == @player_name
      @stats       = { games: 0, wins: 0, losses: 0, win_rate: 0, kills: 0, deaths: 0, assists: 0, kda: 0.0,
                       avg_kills: 0.0, avg_deaths: 0.0, avg_assists: 0.0,
                       avg_cs: 0.0, avg_cs_min: 0.0, avg_gold: 0.0, avg_dmg: 0.0 }
      @champ_stats   = []
      @match_history = []
      @games_index   = {}
      set_meta_tags(title: "#{@player_name} — #{@player_team} — Kings Lendas Cup")
      return
    end

    @player_name  = player_games.first["Link"]
    @player_team  = player_games.first["Team"]
    @player_role  = player_games.first["Role"]
    @team_info    = team_data(@player_team)
    @is_captain   = TEAMS_DATA[@player_team]&.dig(:captain) == @player_name

    set_meta_tags(title: "#{@player_name} — #{@player_team} — Kings Lendas Cup")

    @games_index   = db_games.index_by { |g| g["UniqueGame"] }

    kills   = player_games.sum { |g| g["Kills"].to_i }
    deaths  = player_games.sum { |g| g["Deaths"].to_i }
    assists = player_games.sum { |g| g["Assists"].to_i }
    wins    = player_games.count { |g| (sg = @games_index[g["UniqueGame"]]) && sg["Winner"] == g["Team"] }

    total_minutes = player_games.sum { |g| @games_index[g["UniqueGame"]]&.dig("Gamelength").to_f }
    avg_cs_min    = total_minutes > 0 ? (player_games.sum { |g| g["CS"].to_i }.to_f / total_minutes).round(1) : 0.0

    @stats = {
      games:       player_games.length,
      wins:        wins,
      losses:      player_games.length - wins,
      win_rate:    player_games.length > 0 ? (wins.to_f / player_games.length * 100).round : 0,
      kills:       kills,
      deaths:      deaths,
      assists:     assists,
      kda:         deaths.zero? ? (kills + assists).to_f : ((kills + assists).to_f / deaths).round(2),
      avg_kills:   (kills.to_f / player_games.length).round(1),
      avg_deaths:  (deaths.to_f / player_games.length).round(1),
      avg_assists: (assists.to_f / player_games.length).round(1),
      avg_cs:      (player_games.sum { |g| g["CS"].to_i }.to_f / player_games.length).round(1),
      avg_cs_min:  avg_cs_min,
      avg_gold:    (player_games.sum { |g| g["Gold"].to_i }.to_f / player_games.length).round(0),
      avg_dmg:     (player_games.sum { |g| g["DamageToChampions"].to_i }.to_f / player_games.length).round(0)
    }

    # Per champion stats
    @champ_stats = player_games.group_by { |g| g["Champion"] }.map do |champ, games|
      k = games.sum { |g| g["Kills"].to_i }
      d = games.sum { |g| g["Deaths"].to_i }
      a = games.sum { |g| g["Assists"].to_i }
      w = games.count { |g| (sg = @games_index[g["UniqueGame"]]) && sg["Winner"] == g["Team"] }
      {
        "champion"   => champ,
        "games"      => games.length,
        "wins"       => w,
        "kda"        => d.zero? ? (k + a).to_f : ((k + a).to_f / d).round(2),
        "avg_kills"  => (k.to_f / games.length).round(1),
        "avg_deaths" => (d.to_f / games.length).round(1),
        "avg_assists"=> (a.to_f / games.length).round(1),
        "avg_cs"     => (games.sum { |g| g["CS"].to_i }.to_f / games.length).round(1)
      }
    end.sort_by { |c| -c["games"] }

    @match_history = player_games.reverse
  end
end
