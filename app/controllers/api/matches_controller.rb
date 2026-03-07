module Api
  class MatchesController < BaseController
    def index
      render json: db_schedule
    end

    def show
      game = db_games.find { |g| g["UniqueGame"] == params[:id] }
      if game
        game_players = db_players.select { |p| p["UniqueGame"] == params[:id] }
        render json: { game: game, players: game_players }
      else
        render json: { error: "Game not found" }, status: :not_found
      end
    end
  end
end
