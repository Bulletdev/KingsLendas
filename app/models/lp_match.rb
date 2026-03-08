class LpMatch < LeaguepediaRecord
  scope :for_overview, ->(page) { where(overview_page: page) }
  scope :played,       -> { where.not(winner: [ nil, "" ]) }
  scope :upcoming,     -> { where(winner: [ nil, "" ]) }
  scope :group_stage,  -> { where("phase IS NULL OR phase = '' OR (phase NOT LIKE '%quarter%' AND phase NOT LIKE '%semi%' AND phase NOT LIKE '%final%')") }
  scope :playoffs,     -> { where("phase LIKE '%quarter%' OR phase LIKE '%semi%' OR phase LIKE '%final%'") }
  scope :ordered,      -> { order(datetime_utc: :desc) }

  def as_leaguepedia_hash
    {
      "Team1"       => team1.to_s,
      "Team2"       => team2.to_s,
      "DateTime_UTC"=> datetime_utc.to_s,
      "BestOf"      => best_of.to_s,
      "Winner"      => winner.to_s,
      "Team1Score"  => team1_score.to_s,
      "Team2Score"  => team2_score.to_s,
      "MatchDay"    => match_day.to_s,
      "Phase"       => phase.to_s,
      "Winner_Side" => ""
    }
  end
end
