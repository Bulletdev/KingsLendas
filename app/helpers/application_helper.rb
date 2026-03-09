module ApplicationHelper
  LANE_ICONS = {
    "top"     => "/lane-icon/top.svg",
    "jungle"  => "/lane-icon/jungle.svg",
    "mid"     => "/lane-icon/mid.svg",
    "bot"     => "/lane-icon/bot.webp",
    "adc"     => "/lane-icon/bot.webp",
    "support" => "/lane-icon/supp.svg",
    "coach"   => "/lane-icon/coach.png"
  }.freeze

  # -------------------------------------------------------
  # RetroPanel — portado do prostaff-analytics-hub/RetroPanel.tsx
  # Uso: <%= retro_panel(title: "X", category: "// Y") do %> ... <% end %>
  # -------------------------------------------------------
  def retro_panel(title:, category: nil, subtitle: nil, footer: "Kings Lendas Cup", &block)
    content = capture(&block)
    tag.div(class: "retro-panel") do
      header = tag.div(class: "retro-panel-header") do
        bar    = tag.div(class: "retro-panel-header-bar")
        cat    = category ? tag.span(category, class: "retro-badge") : "".html_safe
        sub    = subtitle ? tag.span(subtitle, style: "font-size:9px;color:var(--retro-gold-dim);letter-spacing:0.05em;white-space:nowrap;font-family:var(--retro-font)") : "".html_safe
        titles = tag.div(class: "flex items-end justify-between gap-2") do
          tag.span(title, class: "retro-title") + sub
        end
        hcontent = tag.div(class: "retro-panel-header-content") { cat + titles }
        corners  = tag.div(class: "retro-corners")
        bar + hcontent + corners
      end

      divider = tag.div(class: "retro-panel-divider")

      body = tag.div(class: "retro-panel-body") do
        tag.div(content, class: "retro-panel-body-inner")
      end

      diamond = tag.div(class: "retro-diamond")
      line_l  = tag.div(style: "width:24px;height:1px;background:linear-gradient(to right,var(--retro-gold),transparent)")
      line_r  = tag.div(style: "width:24px;height:1px;background:linear-gradient(to left,var(--retro-gold),transparent)")
      foot_l  = tag.div(class: "flex items-center gap-2") { diamond + line_l }
      foot_r  = tag.div(class: "flex items-center gap-2") { line_r + tag.div(class: "retro-diamond") }
      footer_el = tag.div(class: "retro-panel-footer") do
        foot_l + tag.span(footer, class: "retro-panel-footer-label") + foot_r
      end

      header + divider + body + footer_el
    end
  end

  # -------------------------------------------------------
  # Team logo — uses real logo image, falls back to colored circle
  # -------------------------------------------------------
  def team_logo(team_name, size: 32, css_class: "")
    data  = TEAMS_DATA[team_name]
    logo  = data&.dig(:logo)
    abbr  = data&.dig(:abbr) || team_name.to_s.first(3).upcase
    color = data&.dig(:color) || "#C89B3C"

    style = "width:#{size}px;height:#{size}px;min-width:#{size}px;"

    if logo.present?
      image_tag(logo, alt: abbr, width: size, height: size,
                class: "rounded-full object-cover flex-shrink-0 #{css_class}",
                style: style,
                loading: "lazy",
                onerror: "this.onerror=null;this.style.display='none';this.insertAdjacentHTML('afterend',`<div style='#{style}background:#{color};border-radius:9999px;display:inline-flex;align-items:center;justify-content:center;'><span style='color:#fff;font-weight:700;font-size:#{[ size/3, 8 ].max}px'>#{abbr}</span></div>`)")
    else
      content_tag(:div,
        content_tag(:span, abbr, class: "font-bold text-white leading-none",
                    style: "font-size:#{[ size/3, 8 ].max}px;"),
        class: "inline-flex items-center justify-center rounded-full flex-shrink-0 #{css_class}",
        style: "#{style}background:#{color};"
      )
    end
  end

  # -------------------------------------------------------
  # Player photo — uses real photo, falls back to colored avatar
  # -------------------------------------------------------
  def player_photo(player_name, team_name = nil, size: 80, css_class: "")
    data   = TEAMS_DATA[team_name]
    # Strip " (Full Name)" parentheticals from Leaguepedia links (e.g. "SCARY (Artur Queiroz)" → "SCARY")
    short_name = player_name.to_s.sub(/\s*\(.*\)\z/, "").strip
    member = data&.dig(:roster)&.find do |m|
      m[:player] == player_name ||
        m[:link].to_s == short_name ||
        m[:player].casecmp?(short_name)
    end
    photo  = member&.dig(:photo)
    color  = data&.dig(:color) || "#C89B3C"
    initials = player_name.to_s.first(2).upcase

    style = "width:#{size}px;height:#{size}px;min-width:#{size}px;"

    if photo.present?
      image_tag(photo, alt: player_name, width: size, height: size,
                class: "rounded-full object-cover object-top flex-shrink-0 #{css_class}",
                style: style,
                loading: "lazy",
                onerror: "this.onerror=null;this.style.display='none';this.insertAdjacentHTML('afterend',`<div style='#{style}background:#{color};border-radius:9999px;display:inline-flex;align-items:center;justify-content:center;font-weight:700;color:#fff;font-size:#{size/3}px;'>#{initials}</div>`)")
    else
      content_tag(:div, initials,
        class: "inline-flex items-center justify-center rounded-full flex-shrink-0 font-black text-white #{css_class}",
        style: "#{style}background:#{color};font-size:#{size/3}px;"
      )
    end
  end

  # -------------------------------------------------------
  # Lane icon — SVG/image from /lane-icon/
  # -------------------------------------------------------
  def lane_icon(role, size: 18, css_class: "")
    path = LANE_ICONS[role.to_s.downcase]
    return "" unless path.present?
    image_tag(path, alt: role, width: size, height: size,
              class: "inline-block object-contain #{css_class}",
              style: "width:#{size}px;height:#{size}px;")
  end

  # -------------------------------------------------------
  # Champion icon via DDragon
  # -------------------------------------------------------
  def champion_icon(champion_name, size: 40, css_class: "")
    url = DdragonService.champion_icon_url(champion_name)
    image_tag(url, alt: champion_name, width: size, height: size,
              class: "rounded object-cover #{css_class}",
              loading: "lazy",
              onerror: "this.style.visibility='hidden'")
  end

  # -------------------------------------------------------
  # Win/Loss badge
  # -------------------------------------------------------
  def win_badge(won)
    if won
      content_tag(:span, "V", class: "inline-flex items-center justify-center w-6 h-6 rounded text-xs font-bold bg-green-500 text-black")
    else
      content_tag(:span, "D", class: "inline-flex items-center justify-center w-6 h-6 rounded text-xs font-bold bg-red-500 text-white")
    end
  end

  # -------------------------------------------------------
  # KDA color class
  # -------------------------------------------------------
  def kda_color(kda)
    v = kda.to_f
    return "text-yellow-400 font-bold" if v >= 5.0
    return "text-green-400"            if v >= 3.0
    return "text-white"                if v >= 1.5
    "text-red-400"
  end

  # -------------------------------------------------------
  # Role helpers
  # -------------------------------------------------------
  def role_label(role)
    {
      "top"     => "Top",
      "jungle"  => "Jungle",
      "mid"     => "Mid",
      "bot"     => "Bot",
      "adc"     => "Bot",
      "support" => "Support",
      "coach"   => "Coach"
    }[role.to_s.downcase] || role.to_s.capitalize
  end

  def role_icon_class(role)
    {
      "top"     => "ri-sword-line",
      "jungle"  => "ri-tree-line",
      "mid"     => "ri-crosshair-2-line",
      "bot"     => "ri-focus-3-line",
      "adc"     => "ri-focus-3-line",
      "support" => "ri-shield-line",
      "coach"   => "ri-book-open-line"
    }[role.to_s.downcase] || "ri-user-line"
  end

  # -------------------------------------------------------
  # Date / time helpers
  # -------------------------------------------------------
  def format_game_duration(duration)
    return "—" if duration.blank?
    if duration.to_s.include?(":")
      duration
    else
      secs = duration.to_i
      "#{secs / 60}:#{(secs % 60).to_s.rjust(2, '0')}"
    end
  end

  def format_datetime_brt(dt_str)
    return "—" if dt_str.blank?
    Time.parse(dt_str).in_time_zone("America/Sao_Paulo").strftime("%d/%m %H:%M")
  rescue ArgumentError
    "—"
  end

  def format_date_brt(dt_str)
    return "—" if dt_str.blank?
    Time.parse(dt_str).in_time_zone("America/Sao_Paulo").strftime("%d/%m/%Y")
  rescue ArgumentError
    "—"
  end

  # -------------------------------------------------------
  # Stats helpers
  # -------------------------------------------------------
  def winpct(wins, games)
    return "0%" if games.to_i.zero?
    "#{(wins.to_f / games.to_i * 100).round}%"
  end

  # -------------------------------------------------------
  # URL slug helpers
  # -------------------------------------------------------
  def team_slug(team_name)
    TEAMS_DATA[team_name]&.dig(:slug) || team_name.to_s.parameterize
  end

  def player_slug(player_name)
    player_name.to_s.parameterize
  end

  # -------------------------------------------------------
  # Nav active class
  # -------------------------------------------------------
  def active_nav(path)
    current_page?(path) ? "text-kl-gold border-b-2 border-kl-gold" : "text-gray-400 hover:text-white"
  end

  # -------------------------------------------------------
  # Phase label
  # -------------------------------------------------------
  def phase_label(phase)
    return "Grupos" if phase.blank?
    phase.gsub("_", " ")
         .gsub(/quarter.finals?/i, "Quartas de Final")
         .gsub(/semi.finals?/i, "Semifinais")
         .gsub(/^final$/i, "Final")
  end

  # -------------------------------------------------------
  # Team color / abbr (also defined in ApplicationController as helper_method)
  # -------------------------------------------------------
  def team_color(team_name)
    TEAMS_DATA[team_name]&.dig(:color) || "#C89B3C"
  end

  def team_abbr(team_name)
    TEAMS_DATA[team_name]&.dig(:abbr) || team_name.to_s.first(3).upcase
  end
end
