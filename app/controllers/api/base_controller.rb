module Api
  class BaseController < ApplicationController
    before_action :set_json_headers

    rescue_from StandardError do |e|
      render json: { error: e.message }, status: :internal_server_error
    end

    private

    def set_json_headers
      response.headers["Content-Type"] = "application/json"
    end
  end
end
