class LpChampionStat < LeaguepediaRecord
  scope :for_tournament, ->(t) { where(tournament: t) }

  def as_leaguepedia_hash
    {
      "Champion" => champion,
      "Picks"    => picks.to_s,
      "Bans"     => bans.to_s,
      "Wins"     => wins.to_s,
      "Games"    => games.to_s
    }
  end
end
