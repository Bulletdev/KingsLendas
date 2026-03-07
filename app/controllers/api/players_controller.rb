module Api
  class PlayersController < BaseController
    def index
      render json: db_players
    end

    def show
      player_data = db_players.select { |p| p["Link"].to_s.parameterize == params[:slug] }
      render json: player_data
    end
  end
end
