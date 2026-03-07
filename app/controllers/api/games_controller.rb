module Api
  class GamesController < BaseController
    def scoreboard
      game = db_games.find { |g| g["UniqueGame"] == params[:id] }
      return render json: { error: "Game not found" }, status: :not_found unless game

      game_players = db_players.select { |p| p["UniqueGame"] == params[:id] }

      render json: {
        game: game,
        players: game_players,
        ddragon_version: DdragonService.version
      }
    end
  end
end
