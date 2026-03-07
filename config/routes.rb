Rails.application.routes.draw do
  root "home#index"

  # Kings Lendas Cup (torneio atual)
  get "/copa",                to: "cup#index",      as: :cup
  get "/copa/classificacao",  to: "cup#standings",  as: :cup_standings
  get "/copa/partidas",       to: "cup#matches",    as: :cup_matches
  get "/copa/picks-bans",     to: "cup#draft",      as: :cup_draft
  get "/copa/campeoes",       to: "cup#champions",  as: :cup_champions
  get "/copa/jogadores",      to: "cup#players",    as: :cup_players
  get "/copa/resultados",     to: "cup#results",    as: :cup_results
  get "/copa/game/:id",       to: "cup#game_scoreboard", as: :cup_game_scoreboard

  # Times
  get "/times",               to: "teams#index",    as: :teams
  get "/times/:slug",         to: "teams#show",     as: :team

  # Jogadores
  get "/jogadores/:slug",     to: "players#show",   as: :player

  # Seasons anteriores
  get "/temporadas",          to: "seasons#index",  as: :seasons
  get "/temporadas/:slug",    to: "seasons#show",   as: :season

  # API interna (JSON para Turbo Frames)
  namespace :api do
    get "standings",            to: "standings#index"
    get "matches",              to: "matches#index"
    get "match/:id",            to: "matches#show",       as: :match
    get "players",              to: "players#index"
    get "player/:slug",         to: "players#show",       as: :player
    get "champions",            to: "champions#index"
    get "team/:slug",           to: "teams#show",         as: :team
    get "game/:id/scoreboard",  to: "games#scoreboard",   as: :game_scoreboard
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
