module Api
  class TeamsController < BaseController
    def show
      team_name = TEAMS_DATA.find { |_, v| v[:slug] == params[:slug] }&.first
      if team_name
        render json: TEAMS_DATA[team_name]
      else
        render json: { error: "Team not found" }, status: :not_found
      end
    end
  end
end
