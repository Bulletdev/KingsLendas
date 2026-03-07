class SeasonsController < ApplicationController
  def index
    set_meta_tags(title: "Temporadas — Kings Lendas")
    @seasons = SEASONS_DATA.map do |slug, data|
      { slug: slug, **data }
    end
  end

  def show
    @slug = params[:slug]
    @season_data = SEASONS_DATA[@slug]
    unless @season_data
      redirect_to seasons_path, alert: "Temporada não encontrada" and return
    end

    set_meta_tags(title: "#{@season_data[:label]} — Kings Lendas")

    tournament = @season_data[:leaguepedia_name]
    @standings = CacheService.fetch("standings:#{@slug}", :standings) do
      leaguepedia.standings(tournament)
    end

    @schedule = CacheService.fetch("schedule:#{@slug}", :schedule) do
      leaguepedia.schedule(tournament)
    end

    @champion_stats = CacheService.fetch("champion_stats:#{@slug}", :champion_stats) do
      leaguepedia.champion_stats(tournament)
    end.first(10)
  end
end
