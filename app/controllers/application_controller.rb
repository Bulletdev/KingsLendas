class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_meta_tags_defaults

  helper_method :team_data, :team_color, :team_abbr, :role_label

  private

  def set_meta_tags_defaults
    set_meta_tags(
      site: "Kings Lendas",
      separator: "—",
      og: {
        site_name: "Kings Lendas",
        image: "https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/a/a3/Kings_Lendas_Cup.png",
        type: "website"
      },
      twitter: { card: "summary_large_image", site: "@ilhadaslendas" }
    )
  end

  def leaguepedia
    @leaguepedia ||= LeaguepediaService.new
  end

  # DB-first helpers: read from SQLite, fallback to API + sync if empty
  def db_schedule(overview_page = CUP_OVERVIEW_PAGE)
    CacheService.fetch("schedule:cup:#{overview_page}", :schedule) do
      rows = LpMatch.where(overview_page: overview_page).ordered
      if rows.any?
        rows.map(&:as_leaguepedia_hash)
      else
        data = leaguepedia.schedule(overview_page)
        if data.any?
          LeaguepediaSyncService.new(overview_page: overview_page).sync_matches
          data
        end
        # Returns nil when empty so skip_nil: true avoids caching rate-limit failures
      end
    end || []
  end

  def db_games(tournament = CUP_TOURNAMENT)
    CacheService.fetch("games:cup:#{tournament}", :match_details) do
      rows = LpGame.where(tournament: tournament).ordered
      if rows.any?
        rows.map(&:as_leaguepedia_hash)
      else
        data = leaguepedia.scoreboard_games(tournament)
        LeaguepediaSyncService.new(tournament: tournament).sync_games if data.any?
        data.presence
      end
    end || []
  end

  def db_players(tournament = CUP_TOURNAMENT)
    CacheService.fetch("players:cup:#{tournament}", :player_stats) do
      rows = LpPlayer.where(tournament: tournament)
      if rows.any?
        rows.map(&:as_leaguepedia_hash)
      else
        data = leaguepedia.scoreboard_players(tournament)
        LeaguepediaSyncService.new(tournament: tournament).sync_players if data.any?
        data.presence
      end
    end || []
  end

  def db_champions(tournament = CUP_TOURNAMENT)
    CacheService.fetch("champion_stats:cup:#{tournament}", :champion_stats) do
      rows = LpChampionStat.where(tournament: tournament)
      if rows.any?
        rows.map(&:as_leaguepedia_hash)
      else
        data = leaguepedia.champion_stats(tournament)
        LeaguepediaSyncService.new(tournament: tournament).sync_champions if data.any?
        data
      end
    end
  end

  def team_data(team_name)
    TEAMS_DATA[team_name] || { abbr: team_name&.first(3)&.upcase, color: "#C89B3C", slug: team_name.to_s.parameterize }
  end

  def team_color(team_name)
    team_data(team_name)[:color] || "#C89B3C"
  end

  def team_abbr(team_name)
    team_data(team_name)[:abbr] || team_name&.first(3)&.upcase
  end

  def role_label(role)
    { "top" => "Top", "jungle" => "Jungle", "mid" => "Mid",
      "bot" => "Bot", "support" => "Support", "coach" => "Coach" }[role.to_s.downcase] || role
  end
end
