module Api
  class StandingsController < BaseController
    def index
      schedule = db_schedule
      render json: leaguepedia.standings_from_schedule(schedule)
    end
  end
end
