class LpPlayer < LeaguepediaRecord
  scope :for_tournament, ->(t) { where(tournament: t) }
  scope :for_player,     ->(slug) { where(player_link: slug) }

  def self.search_fts(query)
    return none if query.blank?
    ids = connection.select_values(
      "SELECT rowid FROM lp_players_fts WHERE lp_players_fts MATCH #{connection.quote(query + '*')}"
    )
    where(id: ids)
  end

  def as_leaguepedia_hash
    {
      "UniqueGame"          => unique_game,
      "Link"                => player_link.to_s,
      "Champion"            => champion.to_s,
      "Kills"               => kills.to_s,
      "Deaths"              => deaths.to_s,
      "Assists"             => assists.to_s,
      "CS"                  => cs.to_s,
      "Gold"                => gold.to_s,
      "DamageToChampions"   => damage_to_champions.to_s,
      "Team"                => team.to_s,
      "Role"                => role.to_s,
      "Side"                => side.to_s
    }
  end
end
