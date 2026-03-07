class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sync
    secret = ENV["ADMIN_SYNC_TOKEN"].presence || "kl-sync-2026"
    unless request.headers["X-Sync-Token"] == secret || params[:token] == secret
      return render plain: "unauthorized", status: :unauthorized
    end

    results = LeaguepediaSyncService.new.sync_all
    render plain: "sync done: #{results.inspect}", status: :ok
  rescue => e
    render plain: "error: #{e.message}", status: :internal_server_error
  end
end
