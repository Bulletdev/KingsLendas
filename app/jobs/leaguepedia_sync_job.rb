class LeaguepediaSyncJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff — respeita rate limit da API
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    Rails.logger.info "[LeaguepediaSyncJob] Starting sync..."

    syncer = LeaguepediaSyncService.new

    matches = syncer.sync_matches
    Rails.logger.info "[LeaguepediaSyncJob] matches: #{matches}"
    sleep 2

    games = syncer.sync_games
    Rails.logger.info "[LeaguepediaSyncJob] games: #{games}"
    sleep 2

    players = syncer.sync_players
    Rails.logger.info "[LeaguepediaSyncJob] players: #{players}"
    sleep 2

    champions = syncer.sync_champions
    Rails.logger.info "[LeaguepediaSyncJob] champions: #{champions}"

    Rails.cache.clear
    Rails.logger.info "[LeaguepediaSyncJob] Done. Cache cleared."
  end
end
