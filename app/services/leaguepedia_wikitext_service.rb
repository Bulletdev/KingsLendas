# Fallback parser for Leaguepedia scoreboard data via MediaWiki action=parse.
# Used when the ScoreboardGames/ScoreboardPlayers Cargo tables are inaccessible.
class LeaguepediaWikitextService
  BASE_URL = "https://lol.fandom.com/api.php"

  OVERVIEW_PAGE = "IDL Kings Lendas Cup"

  # Subpage title → tab name used in UniqueGame IDs
  SCOREBOARD_PAGES = {
    "IDL Kings Lendas Cup/Scoreboards"                          => "Day 1",
    "IDL Kings Lendas Cup/Scoreboards/Day 2"                   => "Day 2",
    "IDL Kings Lendas Cup/Scoreboards/Day 3"                   => "Day 3",
    "IDL Kings Lendas Cup/Scoreboards/Quarterfinals to Finals" => "Quarterfinals to Finals",
  }.freeze

  POSITION_ROLES = %w[top jungle mid bot support].freeze

  def initialize
    @conn = Faraday.new(BASE_URL) do |f|
      f.request :retry, max: 2, interval: 10, backoff_factor: 2,
                retry_statuses: [ 429, 500, 502, 503, 504 ]
      f.request :url_encoded
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def all_games
    results = []
    SCOREBOARD_PAGES.each do |page_title, tab_name|
      wikitext = fetch_wikitext(page_title)
      next if wikitext.blank?
      games = parse_games(wikitext, tab_name)
      Rails.logger.info "[WikitextService] #{page_title}: #{games.length} games parsed"
      results.concat(games)
      sleep 2
    end
    results
  end

  def all_players
    results = []
    SCOREBOARD_PAGES.each do |page_title, tab_name|
      wikitext = fetch_wikitext(page_title)
      next if wikitext.blank?
      players = parse_players(wikitext, tab_name)
      Rails.logger.info "[WikitextService] #{page_title}: #{players.length} player rows parsed"
      results.concat(players)
      sleep 2
    end
    results
  end

  private

  def fetch_wikitext(page_title)
    resp = @conn.get("", {
      action: "parse",
      page:   page_title,
      prop:   "wikitext",
      format: "json"
    })
    resp.body.dig("parse", "wikitext", "*") || ""
  rescue => e
    Rails.logger.warn "[WikitextService] fetch failed for #{page_title}: #{e.message}"
    ""
  end

  # ── Game-level data ──────────────────────────────────────────────────────────

  def parse_games(wikitext, tab_name)
    blocks = extract_template_blocks(wikitext, "Scoreboard/Season")
    blocks.each_with_index.filter_map do |block, idx|
      params = extract_top_level_params(block)
      build_game(params, tab_name, idx + 1)
    end
  end

  def build_game(params, tab_name, match_n)
    team1 = params["team1"]&.strip.presence
    team2 = params["team2"]&.strip.presence
    return nil if team1.nil? || team2.nil?

    winner_n = params["winner"]&.strip
    winner   = winner_n == "1" ? team1 : (winner_n == "2" ? team2 : nil)

    unique_game = "#{OVERVIEW_PAGE}_#{tab_name}_#{match_n}_1"

    bans1  = (1..5).map { |i| params["team1ban#{i}"]&.strip&.capitalize }.compact.reject { |b| b.casecmp("none").zero? }.join(",")
    bans2  = (1..5).map { |i| params["team2ban#{i}"]&.strip&.capitalize }.compact.reject { |b| b.casecmp("none").zero? }.join(",")

    {
      "UniqueGame"  => unique_game,
      "Tournament"  => OVERVIEW_PAGE,
      "Team1"       => team1,
      "Team2"       => team2,
      "Winner"      => winner,
      "Gamelength"  => params["gamelength"]&.strip,
      "DateTime_UTC" => build_datetime(params),
      "Team1Picks"  => nil,
      "Team2Picks"  => nil,
      "Team1Bans"   => bans1,
      "Team2Bans"   => bans2,
      "Team1Gold"   => params["team1g"]&.strip.to_i,
      "Team2Gold"   => params["team2g"]&.strip.to_i,
      "Team1Kills"  => params["team1k"]&.strip.to_i,
      "Team2Kills"  => params["team2k"]&.strip.to_i,
      "Patch"       => params["patch"]&.strip,
      "WinType"     => nil,
    }
  end

  # ── Player-level data ────────────────────────────────────────────────────────

  def parse_players(wikitext, tab_name)
    blocks = extract_template_blocks(wikitext, "Scoreboard/Season")
    players = []

    blocks.each_with_index do |block, idx|
      params     = extract_top_level_params(block)
      team1      = params["team1"]&.strip.presence
      team2      = params["team2"]&.strip.presence
      next if team1.nil? || team2.nil?

      unique_game = "#{OVERVIEW_PAGE}_#{tab_name}_#{idx + 1}_1"
      picks1 = []
      picks2 = []

      (1..5).each do |pos|
        blue_block = extract_nested_template(block, "blue#{pos}")
        if blue_block
          p = extract_top_level_params(blue_block)
          link = p["link"]&.strip.presence
          next unless link
          champion = p["champion"]&.strip
          picks1 << champion
          players << build_player(p, unique_game, team1, pos, "1")
        end

        red_block = extract_nested_template(block, "red#{pos}")
        if red_block
          p = extract_top_level_params(red_block)
          link = p["link"]&.strip.presence
          next unless link
          champion = p["champion"]&.strip
          picks2 << champion
          players << build_player(p, unique_game, team2, pos, "2")
        end
      end
    end

    players
  end

  def build_player(params, unique_game, team, position, side)
    {
      "UniqueGame"        => unique_game,
      "Tournament"        => OVERVIEW_PAGE,
      "Link"              => params["link"]&.strip,
      "Champion"          => params["champion"]&.strip,
      "Kills"             => params["kills"]&.strip.to_i,
      "Deaths"            => params["deaths"]&.strip.to_i,
      "Assists"           => params["assists"]&.strip.to_i,
      "CS"                => params["cs"]&.strip.to_i,
      "Gold"              => params["gold"]&.strip.to_i,
      "DamageToChampions" => params["damagetochamps"]&.strip.to_i,
      "Team"              => team,
      "Role"              => role_for(position, params["role_bound_item"]),
      "Side"              => side,
    }
  end

  def role_for(position, role_bound_item)
    rbi = role_bound_item.to_s.downcase
    if rbi.include?("top lane quest")    then "top"
    elsif rbi.include?("jungle quest")  then "jungle"
    elsif rbi.include?("mid lane quest") then "mid"
    elsif rbi.include?("adc quest") || rbi.include?("marksman") then "bot"
    elsif rbi.include?("support")       then "support"
    else POSITION_ROLES[position - 1]
    end
  end

  def build_datetime(params)
    date = params["date"]&.strip
    time = params["time"]&.strip
    return nil if date.blank?
    [ date, time ].compact_blank.join(" ")
  end

  # ── Template parsing helpers ─────────────────────────────────────────────────

  # Returns all top-level {{template_name_prefix ...}} blocks from text.
  def extract_template_blocks(text, template_name_prefix)
    blocks  = []
    pattern = Regexp.new("\\{\\{#{Regexp.escape(template_name_prefix)}", Regexp::IGNORECASE)
    pos     = 0

    while (match_start = text.index(pattern, pos))
      depth  = 0
      cursor = match_start

      while cursor < text.length
        if text[cursor, 2] == "{{"
          depth  += 1
          cursor += 2
        elsif text[cursor, 2] == "}}"
          depth  -= 1
          cursor += 2
          if depth.zero?
            blocks << text[match_start...cursor]
            break
          end
        else
          cursor += 1
        end
      end

      pos = cursor > match_start ? cursor : match_start + 1
    end

    blocks
  end

  # Extracts the nested {{...}} block assigned to a named parameter.
  # e.g. extract_nested_template(block, "blue1") → "{{Scoreboard/Player|...}}"
  def extract_nested_template(block, param_name)
    pattern = Regexp.new("\\|#{Regexp.escape(param_name)}\\s*=\\s*\\{\\{", Regexp::IGNORECASE)
    match   = block.match(pattern)
    return nil unless match

    template_start = match.end(0) - 2
    depth  = 0
    cursor = template_start

    while cursor < block.length
      if block[cursor, 2] == "{{"
        depth  += 1
        cursor += 2
      elsif block[cursor, 2] == "}}"
        depth  -= 1
        cursor += 2
        return block[template_start...cursor] if depth.zero?
      else
        cursor += 1
      end
    end

    nil
  end

  # Splits a template block on top-level pipes (ignoring pipes inside nested {{}}).
  # Returns hash of { param_name_downcase => raw_value_string }.
  def extract_top_level_params(block)
    params = {}
    # Strip the outer {{ and }} so pipes inside the template are at depth 0
    inner = (block.start_with?("{{") && block.end_with?("}}")) ? block[2..-3] : block
    parts  = split_top_level_pipes(inner)

    parts[1..].each do |part|
      eq_idx = part.index("=")
      next unless eq_idx

      key = part[0...eq_idx].strip.downcase
      val = part[(eq_idx + 1)..]
      params[key] = val
    end

    params
  end

  def split_top_level_pipes(text)
    parts   = []
    current = +""
    depth   = 0
    i       = 0

    while i < text.length
      if text[i, 2] == "{{"
        depth   += 1
        current << "{{"
        i       += 2
      elsif text[i, 2] == "}}"
        depth   -= 1
        current << "}}"
        i       += 2
      elsif text[i] == "|" && depth.zero?
        parts << current.dup
        current.clear
        i += 1
      else
        current << text[i]
        i += 1
      end
    end

    parts << current unless current.empty?
    parts
  end
end
