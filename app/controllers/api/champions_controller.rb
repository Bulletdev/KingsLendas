module Api
  class ChampionsController < BaseController
    def index
      render json: db_champions
    end
  end
end
