# DDragon assets service for champion/item images
class DdragonService
  VERSIONS_URL = "https://ddragon.leagueoflegends.com/api/versions.json"
  CDN_BASE     = "https://ddragon.leagueoflegends.com/cdn"

  # Champion name normalizations for DDragon keys
  CHAMPION_NAME_MAP = {
    "AurelionSol"  => "AurelionSol",
    "Belveth"      => "Belveth",
    "Chogath"      => "Chogath",
    "DrMundo"      => "DrMundo",
    "JarvanIV"     => "JarvanIV",
    "Kaisa"        => "Kaisa",
    "KaiSa"        => "Kaisa",
    "Kogmaw"       => "KogMaw",
    "KogMaw"       => "KogMaw",
    "Leblanc"      => "Leblanc",
    "LeBlanc"      => "Leblanc",
    "Leesin"       => "LeeSin",
    "LeeSin"       => "LeeSin",
    "Masteryi"     => "MasterYi",
    "MasterYi"     => "MasterYi",
    "MissFortune"  => "MissFortune",
    "Missfortune"  => "MissFortune",
    "Nunuandwillump" => "Nunu",
    "Nunu"         => "Nunu",
    "RekSai"       => "RekSai",
    "Reksai"       => "RekSai",
    "TahmKench"    => "TahmKench",
    "TwistedFate"  => "TwistedFate",
    "Twistedfate"  => "TwistedFate",
    "Velkoz"       => "Velkoz",
    "Wukong"       => "MonkeyKing",
    "XinZhao"      => "XinZhao",
    "Xinzhao"      => "XinZhao",
    # Wiki lowercase ban names (after .capitalize)
    "Jarvan"       => "JarvanIV",
    "Ksante"       => "KSante",
    "Bardo"        => "Bard",
    "Tahmkench"    => "TahmKench",
    "Drmundo"      => "DrMundo",
    "Aurelionsol"  => "AurelionSol"
  }.freeze

  class << self
    def version
      Rails.cache.fetch("ddragon:version", expires_in: CACHE_TTLS[:ddragon_version]) do
        fetch_version
      end
    end

    def champion_icon_url(champion_name)
      key = normalize_champion_name(champion_name)
      "#{CDN_BASE}/#{version}/img/champion/#{key}.png"
    end

    def champion_splash_url(champion_name)
      key = normalize_champion_name(champion_name)
      "#{CDN_BASE}/img/champion/splash/#{key}_0.jpg"
    end

    def item_icon_url(item_id)
      "#{CDN_BASE}/#{version}/img/item/#{item_id}.png"
    end

    def normalize_champion_name(name)
      return "Nunu" if name.blank?
      clean = name.to_s.gsub(/['\s\-]/, "").gsub("&amp;", "")
      CHAMPION_NAME_MAP[clean] || clean
    end

    private

    def fetch_version
      conn = Faraday.new { |f| f.response :json; f.adapter Faraday.default_adapter }
      response = conn.get(VERSIONS_URL)
      return "16.5.1" unless response.success?
      response.body.first
    rescue Faraday::Error
      "16.5.1"
    end
  end
end
