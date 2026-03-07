class LpGame < ApplicationRecord
  scope :for_tournament, ->(t) { where(tournament: t) }
  scope :ordered,        -> { order(:datetime_utc) }

  def as_leaguepedia_hash
    {
      "UniqueGame"   => unique_game,
      "Tournament"   => tournament,
      "Team1"        => team1.to_s,
      "Team2"        => team2.to_s,
      "Winner"       => winner.to_s,
      "Gamelength"   => gamelength.to_s,
      "DateTime_UTC" => datetime_utc.to_s,
      "Team1Picks"   => team1_picks.to_s,
      "Team2Picks"   => team2_picks.to_s,
      "Team1Bans"    => team1_bans.to_s,
      "Team2Bans"    => team2_bans.to_s,
      "Team1Kills"   => team1_kills.to_s,
      "Team2Kills"   => team2_kills.to_s,
      "Team1Gold"    => team1_gold.to_s,
      "Team2Gold"    => team2_gold.to_s,
      "Patch"        => patch.to_s
    }
  end
end
